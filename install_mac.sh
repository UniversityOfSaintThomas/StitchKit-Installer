#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Verbose mode flag
VERBOSE=false
if [[ "$1" == "--verbose" ]]; then
    VERBOSE=true
fi

# Helper functions
print_step() {
    echo -e "${BLUE}==>${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

# Header
clear
echo "╔════════════════════════════════════════════════╗"
echo "║       StitchKit Installer for macOS           ║"
echo "║          University of St. Thomas             ║"
echo "║         Private Repository Edition            ║"
echo "╚════════════════════════════════════════════════╝"
echo ""

# Step 1: Check for Python 3
print_step "Checking for Python 3..."
if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version 2>&1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
    print_success "Python $PYTHON_VERSION found"
else
    print_warning "Python 3 not found"
    print_step "Installing Python 3..."
    
    # Download Python installer from python.org
    echo "  Downloading Python 3.11..."
    curl -# -o python-installer.pkg https://www.python.org/ftp/python/3.11.0/python-3.11.0-macos11.pkg
    
    echo "  Installing Python (you may be prompted for your password)..."
    sudo installer -pkg python-installer.pkg -target /
    
    # Clean up
    rm python-installer.pkg
    
    # Verify installation
    if command -v python3 &> /dev/null; then
        print_success "Python installed successfully"
    else
        print_error "Python installation failed"
        echo "Please install Python manually from: https://www.python.org/downloads/"
        exit 1
    fi
fi

# Step 2: Check for Git
print_step "Checking for Git..."
if command -v git &> /dev/null; then
    GIT_VERSION=$(git --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
    print_success "Git $GIT_VERSION found"
else
    print_warning "Git not found"
    print_step "Installing Git via Xcode Command Line Tools..."
    echo "  This will open a dialog to install developer tools"
    echo "  Please click 'Install' and wait for completion"
    
    # Trigger Xcode CLI tools installation
    xcode-select --install 2> /dev/null
    
    # Wait for user to complete installation
    echo ""
    read -p "  Press Enter after installation completes..."
    
    # Verify installation
    if command -v git &> /dev/null; then
        print_success "Git installed successfully"
    else
        print_error "Git installation failed"
        echo "Please install Xcode Command Line Tools manually"
        exit 1
    fi
fi

# Step 3: Check for GitHub CLI
print_step "Checking for GitHub CLI..."
if command -v gh &> /dev/null; then
    GH_VERSION=$(gh --version | head -n 1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
    print_success "GitHub CLI $GH_VERSION found"
else
    print_warning "GitHub CLI not found"
    print_step "Installing GitHub CLI..."
    
    # Detect architecture
    ARCH=$(uname -m)
    if [ "$ARCH" = "arm64" ]; then
        GH_ARCH="arm64"
    else
        GH_ARCH="amd64"
    fi
    
    # Download GitHub CLI directly from GitHub releases
    echo "  Downloading GitHub CLI for $ARCH architecture..."
    GH_VERSION="2.40.0"
    curl -# -L -o gh.tar.gz "https://github.com/cli/cli/releases/download/v${GH_VERSION}/gh_${GH_VERSION}_macOS_${GH_ARCH}.tar.gz"
    
    # Extract
    tar -xzf gh.tar.gz
    
    # Move to /usr/local/bin
    echo "  Installing GitHub CLI (you may be prompted for your password)..."
    sudo mkdir -p /usr/local/bin
    sudo mv "gh_${GH_VERSION}_macOS_${GH_ARCH}/bin/gh" /usr/local/bin/
    
    # Clean up
    rm -rf gh.tar.gz "gh_${GH_VERSION}_macOS_${GH_ARCH}"
    
    # Verify installation
    if command -v gh &> /dev/null; then
        print_success "GitHub CLI installed successfully"
    else
        print_error "GitHub CLI installation failed"
        exit 1
    fi
fi

# Step 4: Authenticate with GitHub
echo ""
print_step "Checking GitHub authentication..."
if ! gh auth status &> /dev/null; then
    print_warning "Not authenticated with GitHub"
    echo ""
    echo "You need to authenticate to access the private StitchKit repository."
    echo "This will open your browser for authentication."
    echo ""
    echo "When prompted:"
    echo "  1. Choose 'GitHub.com'"
    echo "  2. Choose 'HTTPS' for protocol"
    echo "  3. Authenticate via browser"
    echo "  4. If your organization uses SSO, authorize for UST"
    echo ""
    read -p "Press Enter to begin authentication..."
    
    gh auth login
    
    # Verify authentication worked
    if ! gh auth status &> /dev/null; then
        print_error "Authentication failed"
        echo "Please try running: gh auth login"
        exit 1
    fi
fi

print_success "GitHub authentication confirmed"

# Step 5: Clone the repository
echo ""
print_step "Cloning StitchKit repository..."

# Check if directory already exists
if [ -d "$HOME/StitchKit" ]; then
    print_warning "StitchKit directory already exists at ~/StitchKit"
    print_info "The Python installer will handle backup and restoration"
    
    # Don't stop - let the Python installer handle the existing installation
    # It has sophisticated backup/restore logic built in
else
    # Clone using gh since directory doesn't exist
    if gh repo clone UniversityOfSaintThomas/StitchKit ~/StitchKit; then
        print_success "Repository cloned successfully"
    else
        print_error "Failed to clone repository"
        echo ""
        echo "Troubleshooting:"
        echo "  1. Check your internet connection"
        echo "  2. Verify GitHub access: gh auth status"
        echo "  3. Ensure you have access to the repository"
        exit 1
    fi
fi

# Clone using gh
cd ~
if gh repo clone UniversityOfSaintThomas/StitchKit StitchKit; then
    print_success "Repository cloned successfully"
    
    # Offer to restore .env if we have one
    if [ ! -z "$RESTORE_ENV" ] && [ -f "$RESTORE_ENV" ]; then
        echo ""
        print_warning "Found previous configuration file"
        read -p "Restore your API credentials from backup? (y/n): " restore_env
        if [ "$restore_env" = "y" ]; then
            cp "$RESTORE_ENV" "$HOME/StitchKit/.env"
            print_success "Configuration restored"
        fi
    fi
else
    print_error "Failed to clone repository"
    # ... rest of error handling
    echo ""
    echo "Troubleshooting:"
    echo "  1. Verify you have access to the repository"
    echo "  2. Check your authentication: gh auth status"
    echo "  3. If using SSO, authorize your token: gh auth refresh -s read:org"
    exit 1
fi

# Step 6: Run Python installer
echo ""
print_step "Running StitchKit setup..."

# Download the Python installer from the public installer repository
print_step "Downloading Python installer..."
curl -fsSL https://raw.githubusercontent.com/UniversityOfSaintThomas/StitchKit-Installer/main/install_stitchkit.py -o /tmp/install_stitchkit.py

if [ -f "/tmp/install_stitchkit.py" ]; then
    echo ""
    echo "────────────────────────────────────────────────"
    echo ""
    
    if [ "$VERBOSE" = true ]; then
        python3 /tmp/install_stitchkit.py --verbose
    else
        python3 /tmp/install_stitchkit.py
    fi
    
    # Clean up
    rm /tmp/install_stitchkit.py
else
    # If download fails, run basic setup
    print_warning "Could not download installer script"
    print_step "Running basic setup..."
    
    cd ~/StitchKit
    
    # Install Python dependencies
    if [ -f "requirements.txt" ]; then
        echo "  Installing Python dependencies..."
        python3 -m pip install -r requirements.txt
    fi
    
    # Create .env if it doesn't exist
    if [ ! -f ".env" ] && [ -f ".env.example" ]; then
        echo "  Creating .env file..."
        cp .env.example .env
        print_warning "Please edit .env with your Canvas credentials"
    fi
fi

echo ""
echo "────────────────────────────────────────────────"
echo ""
print_success "StitchKit installation complete!"
echo ""
echo "Next steps:"
echo "  1. cd ~/StitchKit"
echo "  2. Edit .env with your Canvas API credentials"
echo "  3. python3 main.py"
echo ""
echo "For help, see the README or contact IT support."
echo ""
