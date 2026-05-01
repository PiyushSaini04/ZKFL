// Mock Verifier using signature instead of ZK proof
const crypto = require('crypto');

function signProof(deltaCid, lossBefore, lossAfter, privateKey) {
    const data = `${deltaCid}:${lossBefore}:${lossAfter}`;
    const sign = crypto.createSign('SHA256');
    sign.update(data);
    sign.end();
    return sign.sign(privateKey, 'hex');
}

function verifyProof(deltaCid, lossBefore, lossAfter, signature, publicKey) {
    const data = `${deltaCid}:${lossBefore}:${lossAfter}`;
    const verify = crypto.createVerify('SHA256');
    verify.update(data);
    verify.end();
    return verify.verify(publicKey, signature, 'hex');
}

module.exports = { signProof, verifyProof };
