#!/bin/bash

set -e

echo "--- Starting Post-Create Setup ---"

sudo apt-get update -y

# Install AWS CLI v2
echo "--- Installing AWS CLI ---"
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
rm -rf awscliv2.zip ./aws

# Install PostgreSQL Client
echo "--- Installing PostgreSQL client ---"
sudo apt-get install -y postgresql-client libpq-dev

# Install Node.js and npm for React
echo "--- Installing Node.js and frontend dependencies ---"
# The Universal Image already includes nvm (Node Version Manager)
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
nvm install 18
nvm use 18
cd frontend-react-js
npm install
cd ..

# Install Momento CLI (requires Homebrew)
echo "--- Installing Momento CLI ---"
NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
(echo; echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"') >> /home/vscode/.bashrc
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
brew tap momentohq/tap
brew install momento-cli

echo "--- Post-Create Setup Complete ---"