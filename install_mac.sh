#!/bin/bash

# StitchKit Installer for macOS
# University of St. Thomas
# Private Repository Edition

set -e  # Exit on error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Verbose mode flag
VERBOSE=false
if [ "$1" = "--verbose" ]; then
    VERBOSE=true
fi

# Helper functions
print_step() {
    echo -e "${BLUE}==>${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# Header
echo ""
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
    print_error "Python 3 not found"
    echo "Please install Python 3 from https://www.python.org/downloads/"
    exit 1
fi

# Step 2: Check for Git
echo ""
print_step "Checking for Git..."
if command -v git &> /dev/null; then
    GIT_VERSION=$(git --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
    print_success "Git $GIT_VERSION found"
else
    print_error "Git not found"
    echo "Please install Xcode Command Line Tools:"
    echo "  xcode-select --install"
    exit 1
fi

# Step 3: Check for GitHub CLI
echo ""
print_step "Checking for GitHub CLI..."
if command -v gh &> /dev/null; then
    GH_VERSION=$(gh --version | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
    print_success "GitHub CLI $GH_VERSION found"
else
    print_warning "GitHub CLI not found. Installing..."
    
    # Use the universal .pkg installer
    GH_VERSION="2.81.0"
    GH_URL="https://github.com/cli/cli/releases/download/v${GH_VERSION}/gh_${GH_VERSION}_macOS_universal.pkg"
    
    print_step "Downloading GitHub CLI v${GH_VERSION}..."
    
    # Download the .pkg file
    if curl -L -o /tmp/gh-installer.pkg "$GH_URL" --fail --show-error; then
        # Check file size to ensure successful download
        FILE_SIZE=$(ls -l /tmp/gh-installer.pkg | awk '{print $5}')
        
        if [ "$FILE_SIZE" -lt 1000000 ]; then  # Less than 1MB means something went wrong
            print_error "Download failed - file too small ($FILE_SIZE bytes)"
            echo "Please install GitHub CLI manually from: https://cli.github.com"
            exit 1
        fi
        
        print_step "Installing GitHub CLI (you may be prompted for your password)..."
        
        # Install the .pkg file
        # This requires admin privileges but installs system-wide
        if sudo installer -pkg /tmp/gh-installer.pkg -target /; then
            print_success "GitHub CLI installed successfully"
        else
            print_error "Failed to install GitHub CLI"
            echo "Please install manually from: https://cli.github.com"
            exit 1
        fi
        
        # Clean up
        rm -f /tmp/gh-installer.pkg
        
        # Verify installation
        if ! command -v gh &> /dev/null; then
            print_error "GitHub CLI installation verification failed"
            echo "The installer completed but 'gh' command not found"
            echo "You may need to restart your terminal or add it to PATH"
            exit 1
        fi
    else
        print_error "Failed to download GitHub CLI"
        echo ""
        echo "Please install GitHub CLI manually:"
        echo "  1. Visit: https://cli.github.com"
        echo "  2. Download the installer for macOS"
        echo "  3. Run the installer"
        echo "  4. Re-run this StitchKit installer"
        exit 1
    fi
fi

# Step 4: Check GitHub authentication
echo ""
print_step "Checking GitHub authentication..."
if ! gh auth status &> /dev/null; then
    print_warning "GitHub authentication required"
    echo ""
    echo "You need to authenticate with GitHub to access the private repository."
    echo "Please follow these steps:"
    echo "  1. Choose 'GitHub.com' when prompted"
    echo "  2. Choose 'HTTPS' for protocol"
    echo "  3. Authenticate with your browser"
    echo "  4. If you use SSO, authorize for your organization"
    echo ""
    gh auth login
    
    if ! gh auth status &> /dev/null; then
        print_error "Authentication failed"
        exit 1
    fi
fi
print_success "GitHub authentication confirmed"

# Step 5: Clone the repository (if needed)
echo ""
print_step "Cloning StitchKit repository..."

# Check if directory already exists
if [ -d "$HOME/StitchKit" ]; then
    print_warning "StitchKit directory already exists at ~/StitchKit"
    print_warning "The Python installer will handle backup and restoration"
    # Don't try to clone - just continue to Python installer
else
    # Directory doesn't exist, so clone it
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

# Step 6: Run Python installer
echo ""
print_step "Running StitchKit setup..."

# Download the Python installer from the public installer repository
print_step "Downloading Python installer..."
if curl -fsSL https://raw.githubusercontent.com/UniversityOfSaintThomas/StitchKit-Installer/main/install_stitchkit.py -o /tmp/install_stitchkit.py; then
    echo ""
    echo "────────────────────────────────────────────────"
    echo ""
    
    # Run the Python installer
    if [ "$VERBOSE" = true ]; then
        python3 /tmp/install_stitchkit.py --verbose
    else
        python3 /tmp/install_stitchkit.py
    fi
    
    # Clean up
    rm -f /tmp/install_stitchkit.py
else
    print_warning "Could not download Python installer"
    print_step "Running basic setup..."
    
    cd ~/StitchKit
    
    # Install Python dependencies if requirements.txt exists
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
echo "════════════════════════════════════════════════"
echo ""
print_success "StitchKit installation complete!"
echo ""
echo "To start StitchKit:"
echo "  cd ~/StitchKit"
echo "  python3 main.py"
echo ""
echo "Or use the alias (if configured):"
echo "  stitchkit"
echo ""
