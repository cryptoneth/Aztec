#!/bin/bash

# Colors for styling
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Emojis for flair
CHECKMARK="✅"
CROSS="❌"
STAR="⭐"
ROCKET="🚀"

# Function to print section headers with flair
print_header() {
    echo -e "${CYAN}============================================================"
    echo -e "${CYAN} ${STAR} $1 ${STAR}"
    echo -e "${CYAN}===========================================================${NC}"
}

# Function to check if a command exists
check_command() {
    command -v "$1" &> /dev/null
    return $?
}

# Function to check if a package is installed
check_package() {
    dpkg -l "$1" &> /dev/null
    return $?
}

# Step 0: Clean up previous Aztec installations
print_header "Step 0: Clean Up Previous Aztec Installations"
echo -e "${BLUE}${STAR} Removing any existing Aztec installations...${NC}"
# Remove /root/.aztec directory if it exists
if [ -d "/root/.aztec" ]; then
    sudo rm -rf /root/.aztec
    echo -e "${GREEN}${CHECKMARK} Removed /root/.aztec directory.${NC}"
else
    echo -e "${GREEN}${CHECKMARK} No /root/.aztec directory found. Skipping removal.${NC}"
fi
# Remove Aztec PATH entries from /root/.bash_profile and ~/.bashrc
if [ -f "/root/.bash_profile" ]; then
    sed -i '/\.aztec\/bin/d' /root/.bash_profile
    echo -e "${GREEN}${CHECKMARK} Cleaned Aztec PATH from /root/.bash_profile.${NC}"
fi
if [ -f "$HOME/.bashrc" ]; then
    sed -i '/\.aztec\/bin/d' "$HOME/.bashrc"
    echo -e "${GREEN}${CHECKMARK} Cleaned Aztec PATH from ~/.bashrc.${NC}"
fi
echo -e "${GREEN}${CHECKMARK} Cleanup completed successfully!${NC}"

# Clear screen and display welcome message with provided ASCII art
clear
echo -e "${GREEN}"
cat << "EOF"
_________                        __                 
\_   ___ \_______ ___.__._______/  |_  ____   ____  
/    \  \/\_  __ <   |  |\____ \   __\/  _ \ /    \ 
\     \____|  | \/\___  ||  |_> >  | (  <_> )   |  \
 \______  /|__|   / ____||   __/|__|  \____/|___|  /
        \/        \/     |__|                    \/
  
  Welcome to the Aztec Sequencer Node Setup Script by Crypton
  ${ROCKET} Let's launch your node with style! ${ROCKET}
EOF
echo -e "${NC}"

# Step 1: Follow Crypton on Twitter
print_header "Step 1: Follow Crypton on Twitter"
echo -e "${PURPLE}${STAR} Show some love and follow me on Twitter for updates and support:${NC}"
echo -e "${YELLOW}https://x.com/0xCrypton_${NC}"
echo -e "${PURPLE}This keeps you in the loop with the Aztec community and latest news!${NC}"
echo -e "${YELLOW}Have you followed @0xCrypton_ on Twitter? (y/n):${NC}"
read -r response
if [[ "$response" != "y" && "$response" != "Y" ]]; then
    echo -e "${RED}${CROSS} Please follow the Twitter account and try again.${NC}"
    exit 1
fi
echo -e "${GREEN}${CHECKMARK} Awesome! Thanks for the follow!${NC}"

# Step 2: Install Dependencies (with checks)
print_header "Step 2: Install Dependencies"
echo -e "${BLUE}Checking for required dependencies...${NC}"

# List of required packages
packages="curl iptables build-essential git wget lz4 jq make gcc nano automake autoconf tmux htop nvme-cli libgbm1 pkg-config libssl-dev libleveldb-dev tar clang bsdmainutils ncdu unzip"

all_installed=true
for pkg in $packages; do
    if check_package "$pkg"; then
        echo -e "${GREEN}${CHECKMARK} $pkg is already installed.${NC}"
    else
        echo -e "${YELLOW}${STAR} $pkg is not installed. Will install...${NC}"
        all_installed=false
    fi
done

if ! $all_installed; then
    echo -e "${BLUE}Updating packages and installing missing dependencies...${NC}"
    sudo apt-get update && sudo apt-get upgrade -y
    if [ $? -ne 0 ]; then
        echo -e "${RED}${CROSS} Failed to update packages. Please check your network and try again.${NC}"
        exit 1
    fi
    sudo apt install -y $packages
    if [ $? -ne 0 ]; then
        echo -e "${RED}${CROSS} Dependency installation failed. Please check and try again.${NC}"
        exit 1
    fi
    echo -e "${GREEN}${CHECKMARK} All dependencies installed successfully!${NC}"
else
    echo -e "${GREEN}${CHECKMARK} All required dependencies are already installed! Skipping installation.${NC}"
fi

# Check and install Docker
echo -e "\n${BLUE}Checking for Docker...${NC}"
if check_command docker; then
    echo -e "${GREEN}${CHECKMARK} Docker is already installed.${NC}"
else
    echo -e "${YELLOW}${STAR} Docker not found. Installing Docker...${NC}"
    for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do
        sudo apt-get remove -y $pkg 2>/dev/null
    done
    sudo apt-get update
    if [ $? -ne 0 ]; then
        echo -e "${RED}${CROSS} Failed to update packages for Docker. Please check your network and try again.${NC}"
        exit 1
    fi
    sudo apt-get install -y ca-certificates curl gnupg
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    if [ $? -ne 0 ]; then
        echo -e "${RED}${CROSS} Docker installation failed. Please check and try again.${NC}"
        exit 1
    fi

    echo -e "\nTesting Docker installation..."
    sudo docker run hello-world
    if [ $? -ne 0 ]; then
        echo -e "${RED}${CROSS} Docker test failed. Please check Docker installation and try again.${NC}"
        exit 1
    fi
    sudo systemctl enable docker
    sudo systemctl restart docker
    echo -e "${GREEN}${CHECKMARK} Docker installed successfully!${NC}"
fi
echo -e "${GREEN}${CHECKMARK} Step completed successfully!${NC}"

# Step 3: Install and Update Aztec Tools
print_header "Step 3: Install Aztec Tools"
echo -e "${PURPLE}${ROCKET} Installing Aztec tools...${NC}"
if check_command aztec; then
    echo -e "${GREEN}${CHECKMARK} Aztec tools are already installed.${NC}"
else
    # Automate the PATH prompt by piping 'y'
    echo "y" | bash -i <(curl -s https://install.aztec.network)
    if [ $? -ne 0 ]; then
        echo -e "${RED}${CROSS} Aztec installation failed. Please check and try again.${NC}"
        exit 1
    fi
    echo -e "${GREEN}${CHECKMARK} Aztec tools installed successfully!${NC}"

    echo -e "\n${BLUE}Reloading shell environment to make 'aztec' command available...${NC}"
    # Reload both .bashrc and .bash_profile to cover all cases
    [ -f "$HOME/.bashrc" ] && source "$HOME/.bashrc"
    [ -f "/root/.bash_profile" ] && source "/root/.bash_profile"
    sleep 2
fi

echo -e "\n${BLUE}Verifying Aztec installation...${NC}"
if check_command aztec; then
    echo -e "${GREEN}${CHECKMARK} Aztec command is available!${NC}"
else
    echo -e "${RED}${CROSS} Aztec command not found. Attempting to fix...${NC}"
    echo 'export PATH="$HOME/.aztec/bin:$PATH"' >> "$HOME/.bashrc"
    source "$HOME/.bashrc"
    [ -f "/root/.bash_profile" ] && echo 'export PATH="/root/.aztec/bin:$PATH"' >> "/root/.bash_profile"
    if check_command aztec; then
        echo -e "${GREEN}${CHECKMARK} Fixed! Aztec command is now available.${NC}"
    else
        echo -e "${RED}${CROSS} Failed to make Aztec command available. Please check manually.${NC}"
        exit 1
    fi
fi

echo -e "\n${PURPLE}${STAR} Updating Aztec to alpha-testnet...${NC}"
aztec-up alpha-testnet
if [ $? -ne 0 ]; then
    echo -e "${RED}${CROSS} Aztec update failed. Please check and try again.${NC}"
    exit 1
fi
echo -e "${GREEN}${CHECKMARK} Aztec updated successfully!${NC}"
echo -e "${GREEN}${CHECKMARK} Step completed successfully!${NC}"

# Step 4: Obtain RPC URLs and Ethereum Keys
print_header "Step 4: Obtain RPC URLs and Ethereum Keys"
echo -e "${BLUE}${STAR} 1. Get Sepolia Ethereum RPC URL from Alchemy:${NC}"
echo -e "${YELLOW}Visit https://dashboard.alchemy.com and create a Sepolia Ethereum HTTP API.${NC}"
echo -e "Enter your Sepolia RPC URL (e.g., https://eth-sepolia.g.alchemy.com/v2/...):"
read -r RPC_URL
if [[ -z "$RPC_URL" ]]; then
    echo -e "${RED}${CROSS} RPC URL cannot be empty. Please try again.${NC}"
    exit 1
fi

echo -e "\n${BLUE}${STAR} 2. Get Sepolia Beacon RPC URL from Chainstack:${NC}"
echo -e "${YELLOW}Visit https://chainstack.com/global-nodes/, register, and create a Sepolia testnet project.${NC}"
echo -e "Find the 'Consensus client HTTPS endpoint' (e.g., https://ethereum-sepolia.core.chainstack.com/beacon/...)."
echo -e "Enter your Sepolia Beacon RPC URL:"
read -r BEACON_URL
if [[ -z "$BEACON_URL" ]]; then
    echo -e "${RED}${CROSS} Beacon URL cannot be empty. Please try again.${NC}"
    exit 1
fi

echo -e "\n${BLUE}${STAR} 3. Enter your Ethereum Private Key:${NC}"
echo -e "${YELLOW}Ensure it starts with '0x'. This is your EVM wallet private key.${NC}"
read -r PRIVATE_KEY
if [[ ! "$PRIVATE_KEY" =~ ^0x[0-9a-fA-F]{64}$ ]]; then
    echo -e "${RED}${CROSS} Invalid private key. It must start with '0x' and be 64 hexadecimal characters.${NC}"
    exit 1
fi

echo -e "\n${BLUE}${STAR} 4. Enter your Ethereum Public Address:${NC}"
echo -e "${YELLOW}This is your EVM wallet public address (e.g., 0x...).${NC}"
echo -e "${YELLOW}${STAR} Ensure you deposit at least 2.5 Sepolia ETH into this address to run the node successfully.${NC}"
read -r PUBLIC_ADDRESS
if [[ ! "$PUBLIC_ADDRESS" =~ ^0x[0-9a-fA-F]{40}$ ]]; then
    echo -e "${RED}${CROSS} Invalid public address. It must start with '0x' and be 40 hexadecimal characters.${NC}"
    exit 1
fi

echo -e "\n${BLUE}${STAR} 5. Fetching server public IP...${NC}"
SERVER_IP=$(curl -s ipv4.icanhazip.com)
if [[ -z "$SERVER_IP" ]]; then
    echo -e "${RED}${CROSS} Failed to fetch server IP. Please enter it manually:${NC}"
    read -r SERVER_IP
    if [[ ! "$SERVER_IP" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        echo -e "${RED}${CROSS} Invalid IP address format.${NC}"
        exit 1
    fi
else
    echo -e "${GREEN}${CHECKMARK} Server IP: $SERVER_IP${NC}"
fi
echo -e "${YELLOW}Have you obtained all RPC URLs, keys, and deposited 2.5 Sepolia ETH? (y/n):${NC}"
read -r response
if [[ "$response" != "y" && "$response" != "Y" ]]; then
    echo -e "${RED}${CROSS} Please complete the required actions and try again.${NC}"
    exit 1
fi
echo -e "${GREEN}${CHECKMARK} Great! All inputs collected!${NC}"

# Step 5: Configure Firewall
print_header "Step 5: Configure Firewall and Open Ports"
echo -e "${PURPLE}${ROCKET} Setting up firewall and opening required ports...${NC}"
sudo ufw allow 22
sudo ufw allow ssh
sudo ufw allow 40400
sudo ufw allow 8080
sudo fuser -k 8080/tcp
sudo ufw enable
if [ $? -ne 0 ]; then
    echo -e "${RED}${CROSS} Firewall configuration failed. Please check and try again.${NC}"
    exit 1
fi
echo -e "${GREEN}${CHECKMARK} Firewall configured and ports opened!${NC}"
echo -e "${GREEN}${CHECKMARK} Step completed successfully!${NC}"

# Step 6: Run Sequencer Node
print_header "Step 6: Start Sequencer Node"
echo -e "${BLUE}${STAR} Creating a persistent screen session named 'aztec'...${NC}"
screen -dmS aztec
echo -e "${PURPLE}${ROCKET} Running the Aztec Sequencer Node...${NC}"
screen -S aztec -X stuff "aztec start --node --archiver --sequencer \\
  --network alpha-testnet \\
  --l1-rpc-urls $RPC_URL \\
  --l1-consensus-host-urls $BEACON_URL \\
  --sequencer.validatorPrivateKey $PRIVATE_KEY \\
  --sequencer.coinbase $PUBLIC_ADDRESS \\
  --p2p.p2pIp $SERVER_IP\n"
if [ $? -ne 0 ]; then
    echo -e "${RED}${CROSS} Failed to start Aztec Sequencer Node. Please check the command and try again.${NC}"
    exit 1
fi
echo -e "${GREEN}${CHECKMARK} Sequencer node started in screen session 'aztec'!${NC}"
echo -e "${YELLOW}To reconnect later, use: screen -r aztec${NC}"
echo -e "${PURPLE}The node will keep running even if you disconnect.${NC}"
echo -e "${GREEN}${CHECKMARK} Step completed successfully!${NC}"

# Step 7: Sync Node and Get Apprentice Role
print_header "Step 7: Sync Node and Earn Apprentice Role"
echo -e "${BLUE}${STAR} Your node is syncing. This may take a few minutes...${NC}"
echo -e "${YELLOW}${STAR} IMPORTANT: Wait at least 10-20 minutes for the node to sync before proceeding. Don't forget to earn the Apprentice role!${NC}"
echo -e "${PURPLE}Navigate to the 'operators | start-here' channel in the Aztec Discord Server.${NC}"
echo -e "To earn the Apprentice role, follow these steps after syncing:"
echo -e "\n${BLUE}1. Get the block number:${NC}"
echo -e "${YELLOW}curl -s -X POST -H 'Content-Type: application/json' -d '{\"jsonrpc\":\"2.0\",\"method\":\"node_getL2Tips\",\"params\":[],\"id\":67}' http://localhost:8080 | jq -r '.result.proven.number'${NC}"
echo -e "${PURPLE}Example output: 66666${NC}"
echo -e "\n${BLUE}2. Use the block number to get the proof:${NC}"
echo -e "${YELLOW}curl -s -X POST -H 'Content-Type: application/json' -d '{\"jsonrpc\":\"2.0\",\"method\":\"node_getArchiveSiblingPath\",\"params\":[\"block-number\",\"block-number\"],\"id\":67}' http://localhost:8080 | jq -r \".result\"${NC}"
echo -e "${PURPLE}Replace 'block-number' with the number from step 1.${NC}"
echo -e "\n${BLUE}3. In the Discord 'operators | start-here' channel, run:${NC}"
echo -e "${YELLOW}/operator start${NC}"
echo -e "${PURPLE}Provide your public address (${PUBLIC_ADDRESS}), block number, and proof when prompted.${NC}"
echo -e "${GREEN}${CHECKMARK} You should receive the Apprentice role instantly!${NC}"
echo -e "${YELLOW}${STAR} Don't skip this step! Have you earned the Apprentice role in Discord? (y/n):${NC}"
read -r response
if [[ "$response" != "y" && "$response" != "Y" ]]; then
    echo -e "${RED}${CROSS} Please follow the Discord instructions and earn the Apprentice role before proceeding.${NC}"
    exit 1
fi
echo -e "${GREEN}${CHECKMARK} Congrats on earning the Apprentice role!${NC}"

# Step 8: Display Validator Registration Command
print_header "Step 8: Register as Validator (Try Later)"
echo -e "${YELLOW}${STAR} Important: If you see 'Error: ValidatorQuotaFilledUntil', the validator quota is full. Wait a few hours or try tomorrow.${NC}"
echo -e "${PURPLE}Below is the command to register as a validator:${NC}"
echo -e "\n${YELLOW}aztec add-l1-validator \\"
echo -e "  --l1-rpc-urls $RPC_URL \\"
echo -e "  --private-key $PRIVATE_KEY \\"
echo -e "  --attester $PUBLIC_ADDRESS \\"
echo -e "  --proposer-eoa $PUBLIC_ADDRESS \\"
echo -e "  --staking-asset-handler 0xF739D03e98e23A7B65940848aBA8921fF3bAc4b2 \\"
echo -e "  --l1-chain-id 11155111${NC}"
echo -e "\n${YELLOW}${STAR} Save this command and run it later when the validator quota is available.${NC}"
echo -e "${GREEN}${CHECKMARK} Setup complete! Your node is running. Check it with: ${YELLOW}screen -r aztec${NC}"
echo -e "${BLUE}Stay updated: ${YELLOW}https://x.com/0xCrypton_${NC}"
exit 0
