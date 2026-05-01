import torch
import torch.nn as nn
import torch.optim as optim
import json
import os

class SimpleMLP(nn.Module):
    def __init__(self):
        super(SimpleMLP, self).__init__()
        self.fc1 = nn.Linear(28*28, 128)
        self.relu = nn.ReLU()
        self.fc2 = nn.Linear(128, 10)

    def forward(self, x):
        x = x.view(-1, 28*28)
        x = self.relu(self.fc1(x))
        x = self.fc2(x)
        return x

def compute_delta(global_model, local_model, clip_threshold=1.0):
    delta = {}
    for name, param in local_model.named_parameters():
        # Δw = w_local_trained - w_global_downloaded
        diff = param.data - global_model.state_dict()[name]
        # Clipping
        norm = torch.norm(diff, p=2)
        if norm > clip_threshold:
            diff = diff * (clip_threshold / norm)
        delta[name] = diff
    return delta

def apply_dp_noise(delta, sigma=0.01):
    for name in delta:
        noise = torch.randn_like(delta[name]) * sigma
        delta[name] += noise
    return delta

def main():
    print("Starting local training...")
    global_model = SimpleMLP()
    local_model = SimpleMLP()
    local_model.load_state_dict(global_model.state_dict())
    
    # Mock data
    inputs = torch.randn(32, 28*28)
    labels = torch.randint(0, 10, (32,))
    
    criterion = nn.CrossEntropyLoss()
    optimizer = optim.SGD(local_model.parameters(), lr=0.01)
    
    with torch.no_grad():
        outputs = global_model(inputs)
        loss_before = criterion(outputs, labels).item()
        
    for epoch in range(5):
        optimizer.zero_grad()
        outputs = local_model(inputs)
        loss = criterion(outputs, labels)
        loss.backward()
        optimizer.step()
        
    with torch.no_grad():
        outputs = local_model(inputs)
        loss_after = criterion(outputs, labels).item()
        
    print(f"Loss Before: {loss_before:.4f}")
    print(f"Loss After: {loss_after:.4f}")
    
    if loss_after < loss_before:
        print("Training successful. Computing delta...")
        delta = compute_delta(global_model, local_model)
        delta = apply_dp_noise(delta)
        torch.save(delta, 'model_delta.pt')
        print("Delta saved to model_delta.pt")
    else:
        print("Loss did not decrease. Discarding update.")

if __name__ == "__main__":
    main()
