import torch
import torch.nn as nn
import torch.nn.functional as F
import torch.optim as optim
from torch.utils.data import Dataset, DataLoader, random_split
import scipy.io
import os
import datetime
import tkinter as tk
from tkinter import filedialog
import numpy as np


class UNet(nn.Module):
    def __init__(self, in_channels, out_channels_mus, out_channels_mua):
        super(UNet, self).__init__()

        self.enc1 = self.conv_block(in_channels, 64)
        self.enc2 = self.conv_block(64, 128)
        self.enc3 = self.conv_block(128, 256)

        self.dec1 = self.up_conv(256, 128)
        self.dec2 = self.up_conv(128, 64)

        self.final_mus = nn.Conv2d(64, out_channels_mus, kernel_size=1)
        self.final_mua = nn.Conv2d(64, out_channels_mua, kernel_size=1)

    def conv_block(self, in_channels, out_channels):
        return nn.Sequential(
            nn.Conv2d(in_channels, out_channels, kernel_size=3, padding=1),
            nn.ReLU(inplace=True),
            nn.Conv2d(out_channels, out_channels, kernel_size=3, padding=1),
            nn.ReLU(inplace=True)
        )

    def up_conv(self, in_channels, out_channels):
        return nn.Sequential(
            nn.ConvTranspose2d(in_channels, out_channels, kernel_size=2, stride=2),
            nn.ReLU(inplace=True)
        )

    def forward(self, x):
        e1 = self.enc1(x)
        e2 = self.enc2(F.max_pool2d(e1, 2))
        e3 = self.enc3(F.max_pool2d(e2, 2))

        d2 = self.dec1(e3)
        d1 = self.dec2(d2 + e2)

        out_mus = self.final_mus(d1 + e1).view(x.size(0), -1)
        out_mua = self.final_mua(d1 + e1).view(x.size(0), -1)

        return out_mus, out_mua


class DOTDataset(Dataset):
    def __init__(self, inputs, mus_outputs, mua_outputs):
        self.inputs = inputs
        self.mus_outputs = mus_outputs
        self.mua_outputs = mua_outputs

    def __len__(self):
        return len(self.inputs)

    def __getitem__(self, idx):
        x = torch.tensor(self.inputs[idx], dtype=torch.float32).unsqueeze(0)
        mus = torch.tensor(self.mus_outputs[idx], dtype=torch.float32)
        mua = torch.tensor(self.mua_outputs[idx], dtype=torch.float32)
        return x, mus, mua


# Function to select folder and process files
def select_folder_and_process_files(max_len=16384):
    root = tk.Tk()
    root.withdraw()
    folder_path = filedialog.askdirectory(title='Select Folder')

    if not folder_path:
        print("No folder selected.")
        return None, None, None, None, None, None, None, None, None, None

    Y_data = []
    mus_data = []
    mua_data = []
    paths = []

    for root_dir, sub_dirs, files in os.walk(folder_path):
        for file in files:
            if file == 'simulation_config_and_results.mat':
                file_path = os.path.join(root_dir, file)
                print(f"Processing file: {file_path}")
                paths.append(root_dir)
                mat_data = scipy.io.loadmat(file_path)

                if 'Y' in mat_data and 'mus' in mat_data and 'mua' in mat_data:
                    Y = mat_data['Y']
                    mus = mat_data['mus'].astype(np.float64).flatten()
                    mua = mat_data['mua'].astype(np.float64).flatten()

                    if hasattr(Y, 'todense'):
                        Y = Y.todense()

                    if isinstance(Y, np.matrix):
                        Y = np.asarray(Y)

                    Y_resized = F.interpolate(torch.tensor(Y, dtype=torch.float32).unsqueeze(0).unsqueeze(0),
                                              size=(128, 128), mode='bilinear', align_corners=False).squeeze(
                        0).squeeze(0).numpy()

                    mus_padded = np.pad(mus, (0, max(0, max_len - len(mus))), 'constant')[:max_len]
                    mua_padded = np.pad(mua, (0, max(0, max_len - len(mua))), 'constant')[:max_len]

                    Y_data.append(Y_resized)
                    mus_data.append(mus_padded)
                    mua_data.append(mua_padded)
                else:
                    print(f"Skipping file {file_path} as it does not contain required arrays.")

    Y_data = np.array(Y_data)
    mus_data = np.array(mus_data)
    mua_data = np.array(mua_data)

    # Normalize the data
    Y_mean = np.mean(Y_data)
    Y_std = np.std(Y_data)
    mus_mean = np.mean(mus_data)
    mus_std = np.std(mus_data)
    mua_mean = np.mean(mua_data)
    mua_std = np.std(mua_data)

    Y_data = (Y_data - Y_mean) / Y_std
    mus_data = (mus_data - mus_mean) / mus_std
    mua_data = (mua_data - mua_mean) / mua_std

    return Y_data, mus_data, mua_data, paths, Y_mean, Y_std, mus_mean, mus_std, mua_mean, mua_std


def train_model():

    Y, mus, mua, _, _, _, _, _, _, _ = select_folder_and_process_files()

    if Y is None:
        return

    # Dataset preparation
    dataset = DOTDataset(Y, mus, mua)
    train_size = int(0.8 * len(dataset))
    val_size = len(dataset) - train_size
    train_dataset, val_dataset = random_split(dataset, [train_size, val_size])
    train_loader = DataLoader(train_dataset, batch_size=16, shuffle=True)
    val_loader = DataLoader(val_dataset, batch_size=16, shuffle=False)

    # Define instantiation
    model = UNet(in_channels=1, out_channels_mus=1, out_channels_mua=1)

    choice = 't'
    while choice not in ['y', 'n']:
        choice = input("Load state dict? [y/n]: ")
        if choice == 'y':
            root = tk.Tk()
            root.withdraw()
            state_dict_path = filedialog.askopenfilename(title='Select State Dict',
                                                         filetypes=[('PyTorch Model', '*.pth')])
            if not state_dict_path:
                print("No state dict selected.")
                return
            else:
                model.load_state_dict(torch.load(state_dict_path))

    choice = ''
    while not choice.isdigit():
        choice = input("Enter number of epochs: ")
        if choice.isdigit():
            number = int(choice)
            if number > 0:
                num_epochs = number
            else:
                print("Invalid input. Please enter a valid positive integer number.")

    while True:
        user_input = input("Enter learning rate: ")
        try:
            lr = float(user_input)
            if lr > 0:
                break
            else:
                print("The number must be greater than 0. Try again.")
        except ValueError:
            print("Invalid input. Please enter a valid positive floating-point number.")

    # Define loss function and optimizer
    criterion = nn.MSELoss()
    optimizer = optim.Adam(model.parameters(), lr=lr)

    best_val_loss = float('inf')

    timestamp = datetime.datetime.now().strftime("%Y-%m-%d_%H-%M-%S")
    save_dir = os.path.join("models", timestamp)
    os.makedirs(save_dir, exist_ok=True)
    best_model_path = os.path.join(save_dir, 'best_model.pth')

    # Training loop

    for epoch in range(num_epochs):
        model.train()
        running_loss = 0.0
        for inputs, mus_targets, mua_targets in train_loader:
            optimizer.zero_grad()

            # Forward pass
            out_mus, out_mua = model(inputs)

            # Compute loss for both mus and mua
            loss_mus = criterion(out_mus, mus_targets)
            loss_mua = criterion(out_mua, mua_targets)
            loss = loss_mus + loss_mua

            # Backward pass and optimization
            loss.backward()
            optimizer.step()
            running_loss += loss.item()

        avg_train_loss = running_loss / len(train_loader)
        print(f"Epoch {epoch + 1}/{num_epochs}, Train Loss: {avg_train_loss}")

        # Validation step
        model.eval()
        val_loss = 0.0
        with torch.no_grad():
            for inputs, mus_targets, mua_targets in val_loader:
                out_mus, out_mua = model(inputs)
                loss_mus = criterion(out_mus, mus_targets)
                loss_mua = criterion(out_mua, mua_targets)
                loss = loss_mus + loss_mua
                val_loss += loss.item()

        avg_val_loss = val_loss / len(val_loader)
        print(f"Epoch {epoch + 1}/{num_epochs}, Val Loss: {avg_val_loss}")

        # Save the best model
        if avg_val_loss < best_val_loss:
            best_val_loss = avg_val_loss
            torch.save(model.state_dict(), best_model_path)
            print(f"Best model saved at epoch {epoch + 1} with val loss {avg_val_loss}")


def reconstruct_results():
    root = tk.Tk()
    root.withdraw()
    state_dict_path = filedialog.askopenfilename(title='Select State Dict', filetypes=[('PyTorch Model', '*.pth')])
    if not state_dict_path:
        print("No state dict selected.")
        return

    model = UNet(in_channels=1, out_channels_mus=1, out_channels_mua=1)
    model.load_state_dict(torch.load(state_dict_path))
    model.eval()

    Y, mus, mua, paths, _, _, mus_mean, mus_std, mua_mean, mua_std = select_folder_and_process_files()
    if Y is None:
        return

    dataset = DOTDataset(Y, mus, mua)
    data_loader = DataLoader(dataset, batch_size=1, shuffle=False)

    for idx, (inputs, mus_targets, mua_targets) in enumerate(data_loader):
        out_mus, out_mua = model(inputs)

        # De-normalize the outputs
        out_mus = out_mus * mus_std + mus_mean
        out_mua = out_mua * mua_std + mua_mean

        save_path = paths[idx]

        scipy.io.savemat(os.path.join(save_path, 'reconstructed_mus.mat'), {'reconstructed_mus': out_mus.detach().cpu().numpy()})
        scipy.io.savemat(os.path.join(save_path, 'reconstructed_mua.mat'), {'reconstructed_mua': out_mua.detach().cpu().numpy()})
        print(f"Reconstructed mus and mua saved to {save_path}")


# Main menu
def main():
    while True:
        print("\n1. Train")
        print("2. Reconstruct")
        print("3. Exit")
        choice = input("Enter your choice: ")

        if choice == '1':
            train_model()
        elif choice == '2':
            reconstruct_results()
        elif choice == '3':
            break
        else:
            print("Invalid choice.")


if __name__ == "__main__":
    main()
