#!/bin/bash

# Function to check if a command was successful
check_status() {
    if [ $? -ne 0 ]; then
        echo "Error: $1 failed"
        exit 1
    fi
}

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

echo "Starting setup script..."

# Initial system update
echo "Updating system packages..."
sudo apt update && sudo apt upgrade -y
check_status "System update"

# Install essential tools
echo "Installing essential tools..."
sudo apt install software-properties-common build-essential wget -y
check_status "Essential tools installation"

# Install Python 3.12
echo "Installing Python 3.12..."
sudo add-apt-repository ppa:deadsnakes/ppa -y
sudo apt update
sudo apt install python3.12 python3.12-venv python3.12-dev python3.12-distutils -y
check_status "Python 3.12 installation"

# Make Python 3.12 the default python3
sudo update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.12 1

# Install pip
echo "Installing pip..."
wget https://bootstrap.pypa.io/get-pip.py
python3 get-pip.py
rm get-pip.py
check_status "Pip installation"

# Remove any existing NVIDIA installations
echo "Removing existing NVIDIA drivers..."
sudo apt autoremove nvidia* --purge -y
check_status "NVIDIA removal"

# Install recommended NVIDIA drivers
echo "Installing recommended NVIDIA drivers..."
ubuntu-drivers devices
sudo ubuntu-drivers autoinstall
check_status "NVIDIA driver installation"

# Create the second part script
echo "Creating second part script..."

cat > ~/setup_exo_part2.sh << 'EOL'
#!/bin/bash

# Function to check if a command was successful
check_status() {
    if [ $? -ne 0 ]; then
        echo "Error: $1 failed"
        exit 1
    fi
}

echo "Starting part 2 of setup..."

# Check NVIDIA installation
echo "Checking NVIDIA installation..."
nvidia-smi
check_status "NVIDIA SMI check"

# Update and upgrade
echo "Updating system packages..."
sudo apt update && sudo apt upgrade -y
check_status "System update"

# Install CUDA toolkit
echo "Installing NVIDIA CUDA toolkit..."
sudo apt install nvidia-cuda-toolkit -y
check_status "CUDA toolkit installation"

# Check CUDA version
echo "Checking CUDA version..."
nvcc --version
check_status "NVCC version check"

# Install cuDNN
echo "Please download the appropriate cuDNN .deb file from NVIDIA website"
echo "https://developer.nvidia.com/rdp/cudnn-download"
echo "Once downloaded, please enter the path to the .deb file:"
read cudnn_path

if [ -f "$cudnn_path" ]; then
    echo "Installing cuDNN..."
    sudo apt install "$cudnn_path"
    check_status "cuDNN .deb installation"
    
    # Install additional cuDNN packages
    sudo apt update
    sudo apt install -y libcudnn8
    sudo apt install -y libcudnn8-dev
    sudo apt install -y libcudnn8-samples
    check_status "cuDNN packages installation"
else
    echo "Error: cuDNN .deb file not found at specified path"
    exit 1
fi

# Verify Python version
echo "Checking Python version..."
python_version=$(python3 --version)
if [[ $python_version < "Python 3.12" ]]; then
    echo "Python version must be >= 3.12. Current version: $python_version"
    exit 1
fi

# Clone and setup exo repository
echo "Cloning exo repository..."
git clone https://github.com/RickyRAV/exo
check_status "Repository cloning"

cd exo
mkdir venv_arc
cd venv_arc
python3 -m venv .
source bin/activate
cd ..

# Install PyTorch
echo "Installing PyTorch..."
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118
check_status "PyTorch installation"

# Install package
echo "Installing exo package..."
pip install -e .
check_status "Package installation"

echo "Setup completed successfully!"
echo "You can now run 'exo' to start the application"

EOL

chmod +x ~/setup_exo_part2.sh
echo "First part completed. System will now reboot."
echo "After reboot, run ~/setup_exo_part2.sh to complete the setup."
echo "Note: You will need to download the cuDNN .deb file from NVIDIA website before running part 2"

# Reboot
read -p "Press Enter to reboot..."
sudo reboot 