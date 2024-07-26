#!/bin/bash

set -e

# Install dependencies
apt-get update && apt-get install -y \
    make \
    build-essential \
    git \
    libgmp-dev \
    pkg-config \
    libssl-dev \
    curl \
    wget \
    software-properties-common \
    && rm -rf /var/lib/apt/lists/*

# Install Go
GO_VERSION=1.22.4
wget -q https://golang.org/dl/go${GO_VERSION}.linux-$(dpkg --print-architecture).tar.gz
tar -C /usr/local -xzf go${GO_VERSION}.linux-$(dpkg --print-architecture).tar.gz
rm go${GO_VERSION}.linux-$(dpkg --print-architecture).tar.gz

# Set Go environment variables
export GOROOT=/usr/local/go
export PATH=$PATH:$GOROOT/bin
export GOPATH=/go
export PATH=$PATH:$GOPATH/bin

# Install Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
export PATH="/root/.cargo/bin:${PATH}"

# Build FHEVM components
cd fhevm-tfhe-cli
git checkout v0.2.4
cargo build --release --features tfhe/x86_64-unix
mkdir -p ~/tfhe-keys
cargo run --release --features tfhe/x86_64-unix -- generate-keys -d ~/tfhe-keys
export FHEVM_GO_KEYS_DIR=~/tfhe-keys

cd ../fhevm-go
git checkout release/0.2.x
cd tfhe-rs
git checkout tfhe-rs-0.6.3
cd ..
make build

# Build geth
cd ..
go run build/ci.go install -static ./cmd/geth
