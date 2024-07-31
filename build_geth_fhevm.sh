#!/bin/bash

set -eo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    local level=$1
    shift
    case $level in
        INFO)  echo -e "${GREEN}[INFO]${NC} $*" ;;
        WARN)  echo -e "${YELLOW}[WARN]${NC} $*" ;;
        ERROR) echo -e "${RED}[ERROR]${NC} $*" ;;
        DEBUG) echo -e "${BLUE}[DEBUG]${NC} $*" ;;
    esac
}

handle_error() {
    log ERROR "An error occurred on line $1"
    log DEBUG "Stack trace:"
    local frame=0
    while caller $frame; do
        ((frame++))
    done
    exit 1
}

trap 'handle_error $LINENO' ERR

install_dependencies() {
    log INFO "Installing dependencies..."
    apt-get update && apt-get install -y \
        make build-essential git libgmp-dev pkg-config libssl-dev \
        curl wget software-properties-common
    if [ $? -eq 0 ]; then
        log INFO "Dependencies installed successfully."
    else
        log ERROR "Failed to install dependencies."
        exit 1
    fi
    apt-get clean && rm -rf /var/lib/apt/lists/*
}

install_go() {
    local GO_VERSION="1.21.12"
    log INFO "Installing Go version ${GO_VERSION}..."
    wget -q "https://golang.org/dl/go${GO_VERSION}.linux-$(dpkg --print-architecture).tar.gz"
    tar -C /usr/local -xzf "go${GO_VERSION}.linux-$(dpkg --print-architecture).tar.gz"
    rm "go${GO_VERSION}.linux-$(dpkg --print-architecture).tar.gz"
    export GOROOT=/usr/local/go
    export PATH=$PATH:$GOROOT/bin
    export GOPATH=/go
    export PATH=$PATH:$GOPATH/bin
    log INFO "Go ${GO_VERSION} installed successfully."
    log DEBUG "Go version: $(go version)"
}

install_rust() {
    log INFO "Installing Rust..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source "$HOME/.cargo/env"
    log INFO "Rust installed successfully."
    log DEBUG "Rust version: $(rustc --version)"
}

build_fhevm() {
    log INFO "Building FHEVM components..."

    export FHEVM_GO_KEYS_DIR=$(pwd)/gitlfs/tfhe-keys

    log DEBUG "Entering fhevm-go directory..."
    cd fhevm-go || { log ERROR "fhevm-go directory not found"; exit 1; }

    log DEBUG "Checking out release/0.2.x..."
    if git checkout release/0.2.x; then
        log INFO "Successfully checked out release/0.2.x"
    else
        log WARN "Unable to checkout release/0.2.x, using current branch: $(git rev-parse --abbrev-ref HEAD)"
    fi

    log DEBUG "Entering tfhe-rs directory..."
    cd tfhe-rs || { log ERROR "tfhe-rs directory not found"; exit 1; }

    log DEBUG "Checking out 0.5.5..."
    if git checkout 0d7a88e; then
        log INFO "Successfully checked out 0.5.5"
    else
        log WARN "Unable to checkout 0.5.5, using current branch: $(git rev-parse --abbrev-ref HEAD)"
    fi

    cd ..
    log DEBUG "Building fhevm-go..."
    make build
    log INFO "FHEVM components built successfully."
}

build_geth() {
    log INFO "Building geth..."
    cd .. || { log ERROR "Unable to navigate to root directory"; exit 1; }
    log DEBUG "Running go build command..."
    go run build/ci.go install -static ./cmd/geth
    log INFO "geth built successfully."
}

main() {
    log INFO "Starting geth FHEVM build process..."
    install_dependencies
    install_go
    install_rust
    build_fhevm
    build_geth
    log INFO "Build process completed successfully!"
    log INFO "You can find the geth binary in ./build/bin/geth"
}

main
