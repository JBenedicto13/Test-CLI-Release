#!/bin/bash

# Source the environment variables if they exist
if [ -f ".env" ]; then
    echo "Loading environment variables from .env file..."
    export $(cat .env | grep -v '^#' | xargs)
fi

# Determine OS and set binary names
OS_NAME=$(uname -s)
ARCH_NAME=$(uname -m)

# Convert OS_NAME to match installer's format
case "$OS_NAME" in
    Linux*)
        OS_NAME="linux"
        ;;
    Darwin*)
        OS_NAME="macos"
        ;;
    CYGWIN*|MINGW32*|MSYS*|MINGW*)
        OS_NAME="windows"
        ;;
    *)
        echo "Unsupported operating system: $OS_NAME"
        exit 1
        ;;
esac

if [[ "$OS_NAME" == "linux" ]]; then
    ENGINE_BINARY="koneksi-engine-linux-amd64"
    CLI_BINARY="koneksi-cli-linux-amd64"
elif [[ "$OS_NAME" == "macos" ]]; then
    if [[ "$ARCH_NAME" == "arm64" ]]; then
        ENGINE_BINARY="koneksi-engine-macos-arm64"
        CLI_BINARY="koneksi-cli-macos-arm64"
    else
        ENGINE_BINARY="koneksi-engine-macos-amd64"
        CLI_BINARY="koneksi-cli-macos-amd64"
    fi
elif [[ "$OS_NAME" == "windows" ]]; then
    ENGINE_BINARY="koneksi-engine-windows-amd64.exe"
    CLI_BINARY="koneksi-cli-windows-amd64.exe"
else
    echo "Unsupported operating system: $OS_NAME"
    exit 1
fi

# Check if we're on Windows
if [[ "$OS_NAME" == "windows" ]]; then
    echo "Running Koneksi Engine and CLI in separate terminals..."
    
    # Check if binaries exist
    if [ ! -f "koneksi-engine/$ENGINE_BINARY" ]; then
        echo "Error: Engine binary not found at koneksi-engine/$ENGINE_BINARY"
        exit 1
    fi
    
    if [ ! -f "koneksi-cli/$CLI_BINARY" ]; then
        echo "Error: CLI binary not found at koneksi-cli/$CLI_BINARY"
        exit 1
    fi
    
    # Run the Koneksi Engine binary in a new terminal window using PowerShell
    echo "Starting Koneksi Engine in a new terminal window..."
    powershell.exe -Command "Start-Process cmd -ArgumentList '/k', 'cd koneksi-engine && echo Running Koneksi Engine... && $ENGINE_BINARY' -WindowStyle Normal"
    
    # Wait a moment for the first terminal to open
    sleep 2
    
    # Run the Koneksi CLI binary in another new terminal window using PowerShell
    echo "Starting Koneksi CLI in a new terminal window..."
    powershell.exe -Command "Start-Process cmd -ArgumentList '/k', 'cd koneksi-cli && echo Running Koneksi CLI... && $CLI_BINARY' -WindowStyle Normal"
    
    echo "Both binaries are now running in separate terminal windows."
    echo "You can close this terminal when ready."
else
    # For Linux/macOS, use xterm or gnome-terminal
    echo "Running Koneksi Engine and CLI in separate terminals..."
    
    # Check if binaries exist
    if [ ! -f "koneksi-engine/$ENGINE_BINARY" ]; then
        echo "Error: Engine binary not found at koneksi-engine/$ENGINE_BINARY"
        exit 1
    fi
    
    if [ ! -f "koneksi-cli/$CLI_BINARY" ]; then
        echo "Error: CLI binary not found at koneksi-cli/$CLI_BINARY"
        exit 1
    fi
    
    if command -v gnome-terminal &> /dev/null; then
        # Run the Koneksi Engine binary in a new terminal window
        echo "Starting Koneksi Engine in a new terminal window..."
        gnome-terminal -- bash -c "echo 'Running Koneksi Engine...'; cd koneksi-engine && ./$ENGINE_BINARY"
        
        # Wait a moment for the first terminal to open
        sleep 2
        
        # Run the Koneksi CLI binary in another new terminal window
        echo "Starting Koneksi CLI in a new terminal window..."
        gnome-terminal -- bash -c "echo 'Running Koneksi CLI...'; cd koneksi-cli && ./$CLI_BINARY"
        
    elif command -v xterm &> /dev/null; then
        # Run the Koneksi Engine binary in a new terminal window
        echo "Starting Koneksi Engine in a new terminal window..."
        xterm -e "echo 'Running Koneksi Engine...'; cd koneksi-engine && ./$ENGINE_BINARY" &
        
        # Wait a moment for the first terminal to open
        sleep 2
        
        # Run the Koneksi CLI binary in another new terminal window
        echo "Starting Koneksi CLI in a new terminal window..."
        xterm -e "echo 'Running Koneksi CLI...'; cd koneksi-cli && ./$CLI_BINARY" &
        
    else
        echo "No supported terminal emulator found. Running in current terminal:"
        echo "Starting Koneksi Engine..."
        cd koneksi-engine && ./$ENGINE_BINARY &
        echo "Starting Koneksi CLI..."
        cd koneksi-cli && ./$CLI_BINARY &
    fi
    
    echo "Both binaries are now running in separate terminal windows."
fi