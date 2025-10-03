#!/usr/bin/env python3
"""
install_stitchkit.py
Python installer for StitchKit
University of St. Thomas
"""

import os
import sys
import subprocess
import shutil
import json
import time
from pathlib import Path
from datetime import datetime

class StitchKitInstaller:
    def __init__(self):
        self.install_dir = Path.home() / "StitchKit"
        self.verbose = False
        self.env_restored = False  # Track if .env was restored
        self.env_has_credentials = False  # Track if credentials are valid
        
    def print_header(self, text):
        """Print a formatted header"""
        print("\n" + "="*50)
        print(f"  {text}")
        print("="*50)
        
    def print_status(self, message, status="info"):
        """Print colored status messages"""
        colors = {
            'success': '\033[92m✓\033[0m',
            'error': '\033[91m✗\033[0m',
            'warning': '\033[93m⚠\033[0m',
            'info': '\033[94mℹ\033[0m'
        }
        prefix = colors.get(status, '')
        print(f"{prefix} {message}")
        
    def print_success(self, message):
        self.print_status(message, "success")
        
    def print_error(self, message):
        self.print_status(message, "error")
        
    def print_warning(self, message):
        self.print_status(message, "warning")
        
    def print_info(self, message):
        self.print_status(message, "info")
        
    def check_python_version(self):
        """Check if Python version meets requirements"""
        if sys.version_info < (3, 7):
            self.print_error(f"Python 3.7+ required. Current: {sys.version}")
            return False
        self.print_success(f"Python {sys.version.split()[0]} detected")
        return True
        
    def check_existing_installation(self):
        """Check for existing StitchKit installation"""
        if self.install_dir.exists():
            self.print_warning(f"StitchKit already installed at {self.install_dir}")
            
            # Check for .env file to preserve
            env_file = self.install_dir / ".env"
            if env_file.exists():
                self.print_info("Found existing .env configuration file")
                
            response = input("\nBackup existing installation? (y/n): ").lower()
            if response == 'y':
                backup_dir = self.backup_existing()
                if backup_dir:
                    # Try to restore .env from backup later
                    self.restore_env_from_backup()
            return True
        return False
        
    def backup_existing(self):
        """Backup existing installation"""
        timestamp = datetime.now().strftime("%Y%m%d-%H%M%S")
        backup_dir = Path.home() / f"StitchKit.backup-{timestamp}"
        
        try:
            self.print_info(f"Creating backup at {backup_dir}")
            shutil.move(str(self.install_dir), str(backup_dir))
            self.print_success("Backup created successfully")
            return backup_dir
        except Exception as e:
            self.print_error(f"Backup failed: {e}")
            return None
            
    def restore_env_from_backup(self):
        """Check for and restore .env from backup"""
        # Look for recent backups
        backup_pattern = "StitchKit.backup-*"
        backups = sorted(Path.home().glob(backup_pattern))
        
        if not backups:
            return False
            
        latest_backup = backups[-1]
        backup_env = latest_backup / ".env"
        
        if backup_env.exists():
            self.print_warning(f"Found backup configuration in {latest_backup.name}")
            response = input("Restore your API credentials from backup? (y/n): ").lower()
            
            if response == 'y':
                # Ensure install directory exists
                self.install_dir.mkdir(parents=True, exist_ok=True)
                shutil.copy2(backup_env, self.install_dir / ".env")
                self.print_success("Configuration restored from backup")
                self.env_restored = True
                
                # Check if the restored .env has valid credentials
                self.env_has_credentials = self.check_env_credentials()
                return True
                
        return False
        
    def check_env_credentials(self):
        """Check if .env has the required credentials filled in"""
        env_file = self.install_dir / ".env"
        if not env_file.exists():
            return False
            
        try:
            with open(env_file, 'r') as f:
                content = f.read()
                
            # Check for required credentials (not just placeholders)
            has_canvas = 'CANVAS_API_KEY=' in content and 'your_canvas_api_key_here' not in content
            has_honorlock_key = 'HONORLOCK_CONSUMER_KEY=' in content and 'your_honorlock_consumer_key_here' not in content
            has_honorlock_secret = 'HONORLOCK_SHARED_SECRET=' in content and 'your_honorlock_shared_secret_here' not in content
            
            # All three required fields must be present and not placeholders
            return has_canvas and has_honorlock_key and has_honorlock_secret
        except Exception:
            return False
            
    def install_dependencies(self):
        """Install Python dependencies"""
        requirements_file = self.install_dir / "requirements.txt"
        
        if not requirements_file.exists():
            self.print_warning("requirements.txt not found")
            return True
            
        self.print_info("Installing Python dependencies...")
        
        try:
            # First upgrade pip
            subprocess.run(
                [sys.executable, "-m", "pip", "install", "--upgrade", "pip"],
                capture_output=True,
                check=False
            )
            
            # Install requirements
            result = subprocess.run(
                [sys.executable, "-m", "pip", "install", "-r", str(requirements_file)],
                capture_output=True,
                text=True
            )
            
            if result.returncode == 0:
                self.print_success("Dependencies installed successfully")
                return True
            else:
                self.print_error(f"Failed to install dependencies: {result.stderr}")
                return False
                
        except Exception as e:
            self.print_error(f"Error installing dependencies: {e}")
            return False
            
    def create_basic_env(self):
        """Create a basic .env file with user-friendly formatting"""
        env_content = """################################################################################
#                                                                              #
#                    🎓 StitchKit Environment Configuration 🎓                 #
#                        University of St. Thomas                             #
#                                                                              #
################################################################################

#===============================================================================
# 🚀 APPLICATION SETTINGS
#===============================================================================

# Application name and branding
STITCHKIT_APP_NAME=StitchKit
STITCHKIT_APP_FULL_NAME=St. Thomas Instructional Technology Command Hub Kit

# Logging level: DEBUG, INFO, WARNING, ERROR, CRITICAL
STITCHKIT_LOG_LEVEL=INFO

#===============================================================================
# 🎨 CANVAS CONFIGURATION - MAIN
#===============================================================================

# [REQUIRED] Your Canvas API Key
# 📝 How to get your Canvas API key:
#    1. Log into Canvas (https://stthomas.instructure.com)
#    2. Click on "Account" in the left sidebar
#    3. Click on "Settings"
#    4. Scroll down to "Approved Integrations"
#    5. Click "+ New Access Token"
#    6. Enter a purpose (e.g., "StitchKit Admin Tools")
#    7. Leave expiration blank for permanent token (or set a date)
#    8. Click "Generate Token"
#    9. ⚠️ COPY THE TOKEN NOW - you won't see it again!
#    10. Paste it below
CANVAS_API_KEY=your_canvas_api_key_here

# Your Canvas instance URL
CANVAS_BASE_URL=https://stthomas.instructure.com

# Your Canvas Account ID (usually 1 for main account)
CANVAS_ACCOUNT_ID=1

#===============================================================================
# 🔄 CANVAS MULTI-ENVIRONMENT SETUP (Future Feature)
#===============================================================================
# Note: These are placeholders for future multi-environment support
# They are NOT currently active in StitchKit

# Production Environment (future feature)
CANVAS_PROD_API_KEY=your_production_api_key_here
CANVAS_PROD_BASE_URL=https://stthomas.instructure.com
CANVAS_PROD_ACCOUNT_ID=1

# Test Environment (future feature)
CANVAS_TEST_API_KEY=your_test_api_key_here
CANVAS_TEST_BASE_URL=https://stthomas.test.instructure.com
CANVAS_TEST_ACCOUNT_ID=1

# Default environment selection (future feature)
CANVAS_DEFAULT_ENV=test

# Canvas integration toggle
CANVAS_ENABLED=true

#===============================================================================
# 📚 CANVAS CATALOG INTEGRATION
#===============================================================================

# [OPTIONAL] Canvas Catalog API Token
# 📝 How to get your Canvas Catalog token:
#    1. Log into Canvas Catalog admin
#    2. Navigate to Admin → Settings → API Access
#    3. Generate a new API token
#    4. Copy and paste it here
CANVAS_CAT_API_TOKEN=your_canvas_catalog_token_here

#===============================================================================
# 🛡️ HONORLOCK INTEGRATION
#===============================================================================

# [REQUIRED] Honorlock Consumer Key
# 📝 How to get Honorlock credentials:
#    1. Contact your Honorlock representative
#    2. Request LTI integration credentials for your institution
#    3. They will provide the consumer key and shared secret
HONORLOCK_CONSUMER_KEY=your_honorlock_consumer_key_here

# [REQUIRED] Honorlock Shared Secret
# ⚠️ Keep this secret! Do not share or commit to version control
HONORLOCK_SHARED_SECRET=your_honorlock_shared_secret_here

# Honorlock Configuration URL (typically the same for all institutions)
HONORLOCK_CONFIG_URL=https://app.honorlock.com/lti_config

#===============================================================================
# 📝 IMPORTANT NOTES
#===============================================================================
# 
# ⚠️ REQUIRED FIELDS:
#    • CANVAS_API_KEY - Must be set for StitchKit to function
#    • HONORLOCK_CONSUMER_KEY - Required for Honorlock integration
#    • HONORLOCK_SHARED_SECRET - Required for Honorlock integration
#
# 💡 SECURITY REMINDER:
#    • Never commit this .env file to Git
#    • Keep your API keys secret and secure
#    • This file contains sensitive credentials
#
#===============================================================================
"""
        env_file = self.install_dir / ".env"
        with open(env_file, 'w') as f:
            f.write(env_content)
            
        self.print_success("Created .env configuration file")
        
    def setup_environment(self):
        """Setup environment configuration"""
        env_file = self.install_dir / ".env"
        
        # If .env was restored from backup, we're done
        if self.env_restored and env_file.exists():
            return True
            
        # If no .env exists, create one
        if not env_file.exists():
            self.create_basic_env()
            
        return True
        
    def create_alias(self):
        """Create stitchkit alias for easy access"""
        try:
            # Detect shell
            shell = os.environ.get('SHELL', '/bin/bash')
            
            if 'zsh' in shell:
                rc_file = Path.home() / '.zshrc'
            elif 'bash' in shell:
                rc_file = Path.home() / '.bashrc'
            else:
                rc_file = Path.home() / '.profile'
                
            alias_line = 'alias stitchkit="cd ~/StitchKit && python3 main.py"'
            
            # Check if alias already exists
            if rc_file.exists():
                with open(rc_file, 'r') as f:
                    if 'alias stitchkit=' in f.read():
                        self.print_info("Alias 'stitchkit' already exists")
                        return
                        
            # Add alias
            with open(rc_file, 'a') as f:
                f.write(f'\n# StitchKit alias\n{alias_line}\n')
                
            self.print_success(f"Created 'stitchkit' alias in {rc_file.name}")
            self.print_info(f"Note: Run 'source ~/{rc_file.name}' or restart terminal to use alias")
            
        except Exception as e:
            self.print_warning(f"Could not create alias: {e}")
            
    def guide_env_setup(self):
        """Guide user through setting up .env file"""
        self.print_header("Configure Canvas API Credentials")
        
        print("\nYou need to add your API credentials to the .env file.")
        print("We'll open the file in nano editor for you.\n")
        
        print("Required credentials:")
        print("  1. CANVAS_API_KEY - Your Canvas API key")
        print("  2. HONORLOCK_CONSUMER_KEY - Your Honorlock consumer key")
        print("  3. HONORLOCK_SHARED_SECRET - Your Honorlock shared secret\n")
        
        print("In nano:")
        print("  • Use arrow keys to navigate")
        print("  • Replace 'your_xxx_here' with actual values")
        print("  • Press Ctrl+O to save")
        print("  • Press Ctrl+X to exit\n")
        
        input("Press Enter to open the editor...")
        
        # Open nano
        env_file = self.install_dir / ".env"
        try:
            subprocess.call(['nano', str(env_file)])
        except FileNotFoundError:
            # If nano isn't available, try vi
            try:
                subprocess.call(['vi', str(env_file)])
            except FileNotFoundError:
                self.print_error("No text editor found. Please edit .env manually")
                return
                
        # Check if they added credentials
        self.env_has_credentials = self.check_env_credentials()
        
        if self.env_has_credentials:
            self.print_success("Credentials configured successfully!")
        else:
            self.print_warning("Some credentials may still need to be configured")
            
    def show_manual_next_steps(self):
        """Show next steps for manual configuration"""
        print("\n" + "="*50)
        print("Next steps:")
        print("\n1. Configure your API credentials:")
        print("   cd ~/StitchKit")
        print("   nano .env")
        print("   (Add your Canvas API key and other credentials)")
        print("\n2. Run StitchKit:")
        print("   python3 main.py")
        print("   Or use the alias: stitchkit")
        print("\nFor help, see the README or contact IT support.")
        
    def run(self):
        """Main installation process"""
        self.print_header("StitchKit Python Installer")
        
        # Parse command line arguments
        if '--verbose' in sys.argv:
            self.verbose = True
            
        # Step 1: Check Python version
        if not self.check_python_version():
            return False
            
        # Step 2: Check for existing installation
        self.check_existing_installation()
        
        # Step 3: Ensure install directory exists
        if not self.install_dir.exists():
            self.print_info(f"Creating installation directory at {self.install_dir}")
            self.install_dir.mkdir(parents=True, exist_ok=True)
            
        # Step 4: Install dependencies
        if not self.install_dependencies():
            self.print_warning("Some dependencies may not have installed correctly")
            
        # Step 5: Setup environment
        if not self.setup_environment():
            return False
            
        # Step 6: Create alias
        self.create_alias()
        
        # Step 7: Final steps based on credential status
        print("\n" + "="*50)
        
        # Check current credential status
        if not self.env_has_credentials:
            self.env_has_credentials = self.check_env_credentials()
            
        if self.env_has_credentials:
            # User has working credentials - launch StitchKit!
            self.print_success("✨ StitchKit is ready to use!")
            print("\nYour credentials are configured. Launching StitchKit...\n")
            
            # Wait a moment for user to read
            time.sleep(2)
            
            # Launch StitchKit
            try:
                os.chdir(self.install_dir)
                subprocess.call([sys.executable, 'main.py'])
            except Exception as e:
                self.print_error(f"Could not launch StitchKit: {e}")
                self.show_manual_next_steps()
                
        else:
            # User needs to configure credentials
            self.print_warning("⚠️ API credentials need to be configured")
            
            response = input("\nWould you like to configure them now? (y/n): ").lower()
            
            if response == 'y':
                self.guide_env_setup()
                
                if self.env_has_credentials:
                    # They successfully added credentials
                    print("\nLaunching StitchKit...")
                    time.sleep(1)
                    try:
                        os.chdir(self.install_dir)
                        subprocess.call([sys.executable, 'main.py'])
                    except Exception as e:
                        self.print_error(f"Could not launch StitchKit: {e}")
                        self.show_manual_next_steps()
                else:
                    # They still need to configure
                    self.show_manual_next_steps()
            else:
                self.show_manual_next_steps()
                
        return True

def main():
    """Main entry point"""
    installer = StitchKitInstaller()
    
    try:
        success = installer.run()
        sys.exit(0 if success else 1)
    except KeyboardInterrupt:
        print("\n\nInstallation cancelled by user")
        sys.exit(1)
    except Exception as e:
        print(f"\nInstallation error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
