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

# Check and install essential tools
echo "Checking and installing essential tools..."
sudo apt update

# Install Git if not present
if ! command_exists git; then
    echo "Installing Git..."
    sudo apt install git -y
    check_status "Git installation"
fi

# Install Python 3.12 if not present or version is lower
if ! command_exists python3.12; then
    echo "Installing Python 3.12..."
    sudo apt install software-properties-common -y
    sudo add-apt-repository ppa:deadsnakes/ppa -y
    sudo apt update
    sudo apt install python3.12 python3.12-venv python3.12-dev -y
    check_status "Python 3.12 installation"
    
    # Make Python 3.12 the default python3
    sudo update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.12 1
fi

# Install pip if not present
if ! command_exists pip3; then
    echo "Installing pip..."
    sudo apt install python3-pip -y
    check_status "Pip installation"
fi

# Update and upgrade
echo "Updating system packages..."
sudo apt update && sudo apt upgrade -y
check_status "System update"

# Remove NVIDIA drivers
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

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

echo "Starting part 2 of setup..."

# Check NVIDIA installation
echo "Checking NVIDIA installation..."
nvidia-smi
check_status "NVIDIA SMI check"

# Update and upgrade again
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

# Verify Python version
echo "Checking Python version..."
python_version=$(python3 --version)
if [[ $python_version < "Python 3.12" ]]; then
    echo "Python version must be >= 3.12. Current version: $python_version"
    exit 1
fi

# Verify pip installation
if ! command_exists pip3; then
    echo "Installing pip..."
    sudo apt install python3-pip -y
    check_status "Pip installation"
fi

# Verify git installation
if ! command_exists git; then
    echo "Installing Git..."
    sudo apt install git -y
    check_status "Git installation"
fi

# Clone repository
echo "Cloning exo repository..."
git clone https://github.com/RickyRAV/exo
check_status "Repository cloning"

# Setup virtual environment
cd exo
mkdir arc_venv
cd arc_venv
python3 -m venv venv
source venv/bin/activate
cd ..

# Install package
echo "Installing exo package..."
pip install -e .
check_status "Package installation"

# Run exo
echo "Starting exo..."
exo

EOL

chmod +x ~/setup_exo_part2.sh
echo "First part completed. System will now reboot."
echo "After reboot, run ~/setup_exo_part2.sh to complete the setup."

# Reboot
read -p "Press Enter to reboot..."
sudo reboot 