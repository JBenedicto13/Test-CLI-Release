#!/bin/bash

echo "Non-GUI Koneksi Installer"

# GET ENGINE REPO INFO
ENGINE_REPO_NAME="koneksi-engine-updates"
ENGINE_REPO_OWNER="koneksi-tech"
ENGINE_REPO_URL="https://github.com/$ENGINE_REPO_OWNER/$ENGINE_REPO_NAME/releases/download"

# GET ENGINE LATEST RELEASE
ENGINE_LATEST_RELEASE=$(curl -s https://api.github.com/repos/$ENGINE_REPO_OWNER/$ENGINE_REPO_NAME/releases/latest | grep -o '"tag_name": "[^"]*"' | cut -d'"' -f4)

# GET CLI REPO INFO
CLI_REPO_NAME="koneksi-cli-updates"
CLI_REPO_OWNER="koneksi-tech"
CLI_REPO_URL="https://github.com/$CLI_REPO_OWNER/$CLI_REPO_NAME/releases/download"

# GET CLI LATEST RELEASE
CLI_LATEST_RELEASE=$(curl -s https://api.github.com/repos/$CLI_REPO_OWNER/$CLI_REPO_NAME/releases/latest | grep -o '"tag_name": "[^"]*"' | cut -d'"' -f4)

# Determine user's OS and architecture
OS_NAME=$(uname -s)

case "$OS_NAME" in
    Linux*)
        echo "Operating System: Linux"
        OS_NAME="linux"
        ;;
    Darwin*)
        echo "Operating System: macOS"
        OS_NAME="macos"
        ;;
    CYGWIN*|MINGW32*|MSYS*|MINGW*)
        echo "Operating System: Windows (via Cygwin/MinGW/MSYS)"
        OS_NAME="windows"
        ;;
    *)
        echo "Operating System: Unknown ($OS_NAME)"
        OS_NAME="unknown"
        ;;
esac

ARCH_NAME=$(uname -m)

#Generate the filename for the Koneksi Engine and CLI binary
if [ "$OS_NAME" == "linux" ]; then
    ENGINE_BINARY_FILENAME="koneksi-engine-linux-amd64"
    CLI_BINARY_FILENAME="koneksi-cli-linux-amd64"
elif [ "$OS_NAME" == "macos" ]; then
    if [ "$ARCH_NAME" == "arm64" ]; then
        ENGINE_BINARY_FILENAME="koneksi-engine-macos-arm64"
        CLI_BINARY_FILENAME="koneksi-cli-macos-arm64"
    else
        ENGINE_BINARY_FILENAME="koneksi-engine-macos-amd64"
        CLI_BINARY_FILENAME="koneksi-cli-macos-amd64"
    fi
elif [ "$OS_NAME" == "windows" ]; then
    ENGINE_BINARY_FILENAME="koneksi-engine-windows-amd64.exe"
    CLI_BINARY_FILENAME="koneksi-cli-windows-amd64.exe"
else
    echo "Unsupported operating system: $OS_NAME"
    exit 1
fi


#Create folder for engine
echo "Creating folder for Koneksi Engine..."
mkdir -p koneksi-engine
cd koneksi-engine

# Prompt user if Koneksi Engine is installed
read -p "Is Koneksi Engine installed? (y/n): " IS_ENGINE_INSTALLED

if [ "$IS_ENGINE_INSTALLED" == "y" ]; then
    echo "Koneksi Engine is installed, skipping installation"
    echo "Proceeding to CLI installation..."
elif [ "$IS_ENGINE_INSTALLED" == "n" ]; then
    echo "Koneksi Engine is not installed, installing..."

    echo "Setting up the Koneksi Engine .env file..."
    #Create the .env file for the Koneksi Engine binary
    echo "Creating .env file for the Koneksi Engine binary"
    cat > .env << EOF
APP_KEY=1oUPOOVVhRoN3SwIdMG4VP6iABNOTmQE     # Secret key for internal authentication or encryption
MODE=release                                 # Use 'debug' to display verbose logs
API_URL=https://staging.koneksi.co.kr        # URL of the gateway or central API the engine will communicate with
RETRY_COUNT=5                                # Number of retry attempts for failed requests or operations
TOKEN_CHECK_INTERVAL=60s                     # Interval for checking if a token is still valid
BACKUP_TASK_COOLDOWN=60s                     # Cooldown period between backup operations
QUEUE_CHECK_INTERVAL=2s                      # Interval for checking processing queues for new tasks
PAUSE_TIMEOUT=30s                            # Timeout duration for pause operations in the backup queue table
EOF

    echo "Downloading the Koneksi Engine binary..."
    # Download the Koneksi Engine binary
    curl -LO $ENGINE_REPO_URL/$ENGINE_LATEST_RELEASE/$ENGINE_BINARY_FILENAME
    chmod +x $ENGINE_BINARY_FILENAME
    echo "Koneksi Engine binary downloaded successfully"
    echo "Proceeding to CLI installation..."
else
    echo "Invalid input, please enter y or n"
    exit 1
fi

#Go back to root folder
cd ..

#Create folder for cli
echo "Creating folder for Koneksi CLI..."
mkdir -p koneksi-cli
cd koneksi-cli

echo "Downloading the Koneksi CLI binary..."
# Download the Koneksi CLI binary
curl -LO $CLI_REPO_URL/$CLI_LATEST_RELEASE/$CLI_BINARY_FILENAME
chmod +x $CLI_BINARY_FILENAME
echo "Koneksi CLI binary downloaded successfully"

#Register CLI to System (Linux/macOS only)
if [[ "$OS_NAME" == "linux" || "$OS_NAME" == "macos" ]]; then
    echo "Registering Koneksi CLI to System..."
    # Get the absolute path to the CLI binary
    CLI_PATH=$(pwd)/$CLI_BINARY_FILENAME
    sudo ln -sf "$CLI_PATH" /usr/local/bin/koneksi
    echo "Koneksi CLI registered to System successfully. Test by running 'koneksi --help'"
else
    echo "CLI registration skipped on Windows (not needed)"
fi

# Export the binary filenames so they can be used by other scripts
export ENGINE_BINARY_FILENAME
export CLI_BINARY_FILENAME

echo ""
echo "Installation completed successfully!"
echo "To run the binaries in separate terminals, use: ./run-engine.sh"

# Ask if user wants to run the binaries immediately
echo ""
read -p "Would you like to run Koneksi Engine and CLI now? (y/n): " RUN_NOW

if [ "$RUN_NOW" == "y" ]; then
    echo "Starting Koneksi Engine and CLI..."
    # Return to root directory where run-engine.sh is located
    cd ..
    if [ -f "run-engine.sh" ]; then
        chmod +x run-engine.sh
        ./run-engine.sh
    else
        echo "Error: run-engine.sh not found in current directory"
        echo "Please run './run-engine.sh' manually to start the binaries"
    fi
elif [ "$RUN_NOW" == "n" ]; then
    echo "You can run the binaries later using: ./run-engine.sh"
else
    echo "Invalid input. You can run the binaries later using: ./run-engine.sh"
fi