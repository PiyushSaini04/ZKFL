require('dotenv').config();
const express = require('express');
const cors = require('cors');
const multer = require('multer');
const path = require('path');
const fs = require('fs');

const app = express();
app.use(cors());
app.use(express.json());

const storage = multer.diskStorage({
    destination: (req, file, cb) => {
        const dir = './uploads';
        if (!fs.existsSync(dir)) fs.mkdirSync(dir);
        cb(null, dir);
    },
    filename: (req, file, cb) => {
        cb(null, Date.now() + '-' + file.originalname);
    }
});
const upload = multer({ storage });

// MOCK IPFS Service
app.post('/api/ipfs/upload', upload.single('file'), (req, res) => {
    if (!req.file) return res.status(400).json({ error: 'No file uploaded' });
    
    const mockCID = 'Qm' + require('crypto').randomBytes(22).toString('hex');
    
    const mappingPath = './uploads/cid_mapping.json';
    let mapping = {};
    if (fs.existsSync(mappingPath)) mapping = JSON.parse(fs.readFileSync(mappingPath));
    mapping[mockCID] = req.file.path;
    fs.writeFileSync(mappingPath, JSON.stringify(mapping, null, 2));

    res.json({ cid: mockCID });
});

app.get('/api/ipfs/download/:cid', (req, res) => {
    const mappingPath = './uploads/cid_mapping.json';
    if (!fs.existsSync(mappingPath)) return res.status(404).json({ error: 'Not found' });
    const mapping = JSON.parse(fs.readFileSync(mappingPath));
    const filePath = mapping[req.params.cid];
    
    if (filePath && fs.existsSync(filePath)) {
        res.download(filePath);
    } else {
        res.status(404).json({ error: 'File not found' });
    }
});

// Mock Aggregation Coordinator trigger
app.post('/api/aggregate', async (req, res) => {
    const { taskId, round } = req.body;
    console.log(`Aggregating round ${round} for task ${taskId}...`);
    await new Promise(r => setTimeout(r, 2000));
    const newGlobalCID = 'Qm' + require('crypto').randomBytes(22).toString('hex');
    res.json({ success: true, newModelCID: newGlobalCID });
});

const PORT = process.env.PORT || 3001;
app.listen(PORT, () => {
    console.log(`Backend server running on port ${PORT}`);
});
