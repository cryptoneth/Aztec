#!/bin/bash

# Colors for styling
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print section headers
print_header() {
    echo -e "${BLUE}============================================================${NC}"
    echo -e "${BLUE} $1 ${NC}"
    echo -e "${BLUE}============================================================${NC}"
}

# Function to prompt for user confirmation
confirm_step() {
    echo -e "${YELLOW}Have you completed this step? (y/n): ${NC}"
    read -r response
    if [[ "$response" != "y" && "$response" != "Y" ]]; then
        echo -e "${RED}Please complete the step and try again.${NC}"
        exit 1
    fi
}

# Function to check if a command exists
check_command() {
    if ! command -v "$1" &> /dev/null; then
        return 1
    fi
    return 0
}

# Clear screen and display welcome message
clear
echo -e "${GREEN}"
cat << "EOF"
  Crypton
  Welcome to the Aztec Sequencer Node Setup Script by Crypton
EOF
echo -e "${NC}"

# Step 1: Follow Crypton on Twitter
print_header "Step 1: Follow Crypton on Twitter"
echo -e "Please follow me on Twitter for updates and support:"
echo -e "${YELLOW}https://x.com/0xCrypton_${NC}"
echo -e "This helps you stay connected with the community and get the latest news."
confirm_step

# Step 2: Install Dependencies
print_header "Step 2: Install Dependencies"
echo -e "Updating packages and installing required dependencies..."
sudo apt-get update && sudo apt-get upgrade -y
sudo apt install -y curl iptables build-essential git wget lz4 jq make gcc nano automake autoconf tmux htop nvme-cli libgbm1 pkg-config libssl-dev libleveldb-dev tar clang bsdmainutils ncdu unzip libleveldb-dev

echo -e "\nInstalling Docker..."
for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do
    sudo apt-get remove -y $pkg 2>/dev/null
done
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo -e "\nTesting Docker installation..."
sudo docker run hello-world
if [ $? -eq 0 ]; then
    echo -e "${GREEN}Docker installed successfully!${NC}"
else
    echo -e "${RED}Docker installation failed. Please check and try again.${NC}"
    exit 1
fi
sudo systemctl enable docker
sudo systemctl restart docker
confirm_step

# Step 3: Install and Update Aztec Tools
print_header "Step 3: Install Aztec Tools"
echo -e "Installing Aztec tools..."
bash -i <(curl -s https://install.aztec.network)
if [ $? -eq 0 ]; then
    echo -e "${GREEN}Aztec tools installed successfully!${NC}"
else
    echo -e "${RED}Aztec installation failed. Please check and try again.${NC}"
    exit 1
fi

echo -e "\nReloading shell environment to make 'aztec' command available..."
# Reload shell environment without requiring logout
source ~/.bashrc
# Add a small delay to ensure environment is updated
sleep 2

echo -e "\nChecking if Aztec is installed..."
if check_command aztec; then
    echo -e "${GREEN}Aztec command is available!${NC}"
else
    echo -e "${RED}Aztec command not found. Trying to fix...${NC}"
    # Attempt to add Aztec to PATH
    echo 'export PATH="$HOME/.aztec/bin:$PATH"' >> ~/.bashrc
    source ~/.bashrc
    if check_command aztec; then
        echo -e "${GREEN}Fixed! Aztec command is now available.${NC}"
    else
        echo -e "${RED}Failed to make Aztec command available. Please check manually.${NC}"
        exit 1
    fi
fi

echo -e "\nUpdating Aztec to alpha-testnet..."
aztec-up alpha-testnet
if [ $? -eq 0 ]; then
    echo -e "${GREEN}Aztec updated successfully!${NC}"
else
    echo -e "${RED}Aztec update failed. Please check and try again.${NC}"
    exit 1
fi
confirm_step

# Step 4: Obtain RPC URLs and Ethereum Keys
print_header "Step 4: Obtain RPC URLs and Ethereum Keys"
echo -e "1. Get Sepolia Ethereum RPC URL from Alchemy:"
echo -e "${YELLOW}Visit https://dashboard.alchemy.com and create a Sepolia Ethereum HTTP API.${NC}"
echo -e "Enter your Sepolia RPC URL (e.g., https://eth-sepolia.g.alchemy.com/v2/...):"
read -r RPC_URL
if [[ -z "$RPC_URL" ]]; then
    echo -e "${RED}RPC URL cannot be empty. Please try again.${NC}"
    exit 1
fi

echo -e "\n2. Get Sepolia Beacon RPC URL from Chainstack:"
echo -e "${YELLOW}Visit https://chainstack.com/global-nodes/, register, and create a Sepolia testnet project.${NC}"
echo -e "Find the 'Consensus client HTTPS endpoint' in your project (e.g., https://ethereum-sepolia.core.chainstack.com/beacon/...)."
echo -e "Enter your Sepolia Beacon RPC URL:"
read -r BEACON_URL
if [[ -z "$BEACON_URL" ]]; then
    echo -e "${RED}Beacon URL cannot be empty. Please try again.${NC}"
    exit 1
fi

echo -e "\n3. Enter your Ethereum Private Key:"
echo -e "${YELLOW}Ensure it starts with '0x'. This is your EVM wallet private key.${NC}"
read -r PRIVATE_KEY
if [[ ! "$PRIVATE_KEY" =~ ^0x[0-9a-fA-F]{64}$ ]]; then
    echo -e "${RED}Invalid private key. It must start with '0x' and be 64 hexadecimal characters.${NC}"
    exit 1
fi

echo -e "\n4. Enter your Ethereum Public Address:"
echo -e "${YELLOW}This is your EVM wallet public address (e.g., 0x...).${NC}"
read -r PUBLIC_ADDRESS
if [[ ! "$PUBLIC_ADDRESS" =~ ^0x[0-9a-fA-F]{40}$ ]]; then
    echo -e "${RED}Invalid public address. It must start with '0x' and be 40 hexadecimal characters.${NC}"
    exit 1
fi

echo -e "\n5. Fetching server public IP..."
SERVER_IP=$(curl -s ipv4.icanhazip.com)
if [[ -z "$SERVER_IP" ]]; then
    echo -e "${RED}Failed to fetch server IP. Please enter it manually:${NC}"
    read -r SERVER_IP
    if [[ ! "$SERVER_IP" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        echo -e "${RED}Invalid IP address format.${NC}"
        exit 1
    fi
else
    echo -e "${GREEN}Server IP: $SERVER_IP${NC}"
fi
confirm_step

# Step 5: Configure Firewall
print_header "Step 5: Configure Firewall and Open Ports"
echo -e "Setting up firewall and opening required ports..."
sudo ufw allow 22
sudo ufw allow ssh
sudo ufw allow 40400
sudo ufw allow 8080
sudo fuser -k 8080/tcp
sudo ufw enable
echo -e "${GREEN}Firewall configured and ports opened.${NC}"
confirm_step

# Step 6: Run Sequencer Node
print_header "Step 6: Start Sequencer Node"
echo -e "Creating a persistent screen session named 'aztec'..."
screen -dmS aztec
echo -e "Running the Aztec Sequencer Node command..."
screen -S aztec -X stuff "aztec start --node --archiver --sequencer \\
  --network alpha-testnet \\
  --l1-rpc-urls $RPC_URL \\
  --l1-consensus-host-urls $BEACON_URL \\
  --sequencer.validatorPrivateKey $PRIVATE_KEY \\
  --sequencer.coinbase $PUBLIC_ADDRESS \\
  --p2p.p2pIp $SERVER_IP\n"
echo -e "${GREEN}Sequencer node started in screen session 'aztec'.${NC}"
echo -e "To reconnect to the session later, use: ${YELLOW}screen -r aztec${NC}"
echo -e購

System: It looks like the response was cut off. Below is the complete updated Bash script, incorporating your request to change the logo to **Crypton** and modifying the final section (Step 8) to include the `Error: ValidatorQuotaFilledUntil` message, instructing the user to try the validator registration command later and exit the script. The script maintains all previous functionality, including the Aztec installation fix, persistent screen session, and user input validation.

```bash
#!/bin/bash

# Colors for styling
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print section headers
print_header() {
    echo -e "${BLUE}============================================================${NC}"
    echo -e "${BLUE} $1 ${NC}"
    echo -e "${BLUE}============================================================${NC}"
}

# Function to prompt for user confirmation
confirm_step() {
    echo -e "${YELLOW}Have you completed this step? (y/n): ${NC}"
    read -r response
    if [[ "$response" != "y" && "$response" != "Y" ]]; then
        echo -e "${RED}Please complete the step and try again.${NC}"
        exit 1
    fi
}

# Function to check if a command exists
check_command() {
    if ! command -v "$1" &> /dev/null; then
        return 1
    fi
    return 0
}

# Clear screen and display welcome message
clear
echo -e "${GREEN}"
cat << "EOF"
  Crypton
  Welcome to the Aztec Sequencer Node Setup Script by Crypton
EOF
echo -e "${NC}"

# Step 1: Follow Crypton on Twitter
print_header "Step 1: Follow Crypton on Twitter"
echo -e "Please follow me on Twitter for updates and support:"
echo -e "${YELLOW}https://x.com/0xCrypton_${NC}"
echo -e "This helps you stay connected with the community and get the latest news."
confirm_step

# Step 2: Install Dependencies
print_header "Step 2: Install Dependencies"
echo -e "Updating packages and installing required dependencies..."
sudo apt-get update && sudo apt-get upgrade -y
sudo apt install -y curl iptables build-essential git wget lz4 jq make gcc nano automake autoconf tmux htop nvme-cli libgbm1 pkg-config libssl-dev libleveldb-dev tar clang bsdmainutils ncdu unzip libleveldb-dev

echo -e "\nInstalling Docker..."
for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do
    sudo apt-get remove -y $pkg 2>/dev/null
done
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo -e "\nTesting Docker installation..."
sudo docker run hello-world
if [ $? -eq 0 ]; then
    echo -e "${GREEN}Docker installed successfully!${NC}"
else
    echo -e "${RED}Docker installation failed. Please check and try again.${NC}"
    exit 1
fi
sudo systemctl enable docker
sudo systemctl restart docker
confirm_step

# Step 3: Install and Update Aztec Tools
print_header "Step 3: Install Aztec Tools"
echo -e "Installing Aztec tools..."
bash -i <(curl -s https://install.aztec.network)
if [ $? -eq 0 ]; then
    echo -e "${GREEN}Aztec tools installed successfully!${NC}"
else
    echo -e "${RED}Aztec installation failed. Please check and try again.${NC}"
    exit 1
fi

echo -e "\nReloading shell environment to make 'aztec' command available..."
# Reload shell environment without requiring logout
source ~/.bashrc
# Add a small delay to ensure environment is updated
sleep 2

echo -e "\nChecking if Aztec is installed..."
if check_command aztec; then
    echo -e "${GREEN}Aztec command is available!${NC}"
else
    echo -e "${RED}Aztec command not found. Trying to fix...${NC}"
    # Attempt to add Aztec to PATH
    echo 'export PATH="$HOME/.aztec/bin:$PATH"' >> ~/.bashrc
    source ~/.bashrc
    if check_command aztec; then
        echo -e "${GREEN}Fixed! Aztec command is now available.${NC}"
    else
        echo -e "${RED}Failed to make Aztec command available. Please check manually.${NC}"
        exit 1
    fi
fi

echo -e "\nUpdating Aztec to alpha-testnet..."
aztec-up alpha-testnet
if [ $? -eq 0 ]; then
    echo -e "${GREEN}Aztec updated successfully!${NC}"
else
    echo -e "${RED}Aztec update failed. Please check and try again.${NC}"
    exit 1
fi
confirm_step

# Step 4: Obtain RPC URLs and Ethereum Keys
print_header "Step 4: Obtain RPC URLs and Ethereum Keys"
echo -e "1. Get Sepolia Ethereum RPC URL from Alchemy:"
echo -e "${YELLOW}Visit https://dashboard.alchemy.com and create a Sepolia Ethereum HTTP API.${NC}"
echo -e "Enter your Sepolia RPC URL (e.g., https://eth-sepolia.g.alchemy.com/v2/...):"
read -r RPC_URL
if [[ -z "$RPC_URL" ]]; then
    echo -e "${RED}RPC URL cannot be empty. Please try again.${NC}"
    exit 1
fi

echo -e "\n2. Get Sepolia Beacon RPC URL from Chainstack:"
echo -e "${YELLOW}Visit https://chainstack.com/global-nodes/, register, and create a Sepolia testnet project.${NC}"
echo -e "Find the 'Consensus client HTTPS endpoint' in your project (e.g., https://ethereum-sepolia.core.chainstack.com/beacon/...)."
echo -e "Enter your Sepolia Beacon RPC URL:"
read -r BEACON_URL
if [[ -z "$BEACON_URL" ]]; then
    echo -e "${RED}Beacon URL cannot be empty. Please try again.${NC}"
    exit 1
fi

echo -e "\n3. Enter your Ethereum Private Key:"
echo -e "${YELLOW}Ensure it starts with '0x'. This is your EVM wallet private key.${NC}"
read -r PRIVATE_KEY
if [[ ! "$PRIVATE_KEY" =~ ^0x[0-9a-fA-F]{64}$ ]]; then
    echo -e "${RED}Invalid private key. It must start with '0x' and be 64 hexadecimal characters.${NC}"
    exit 1
fi

echo -e "\n4. Enter your Ethereum Public Address:"
echo -e "${YELLOW}This is your EVM wallet public address (e.g., 0x...).${NC}"
read -r PUBLIC_ADDRESS
if [[ ! "$PUBLIC_ADDRESS" =~ ^0x[0-9a-fA-F]{40}$ ]]; then
    echo -e "${RED}Invalid public address. It must start with '0x' and be 40 hexadecimal characters.${NC}"
    exit 1
fi

echo -e "\n5. Fetching server public IP..."
SERVER_IP=$(curl -s ipv4.icanhazip.com)
if [[ -z "$SERVER_IP" ]]; then
    echo -e "${RED}Failed to fetch server IP. Please enter it manually:${NC}"
    read -r SERVER_IP
    if [[ ! "$SERVER_IP" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        echo -e "${RED}Invalid IP address format.${NC}"
        exit 1
    fi
else
    echo -e "${GREEN}Server IP: $SERVER_IP${NC}"
fi
confirm_step

# Step 5: Configure Firewall
print_header "Step 5: Configure Firewall and Open Ports"
echo -e "Setting up firewall and opening required ports..."
sudo ufw allow 22
sudo ufw allow ssh
sudo ufw allow 40400
sudo ufw allow 8080
sudo fuser -k 8080/tcp
sudo ufw enable
echo -e "${GREEN}Firewall configured and ports opened.${NC}"
confirm_step

# Step 6: Run Sequencer Node
print_header "Step 6: Start Sequencer Node"
echo -e "Creating a persistent screen session named 'aztec'..."
screen -dmS aztec
echo -e "Running the Aztec Sequencer Node command..."
screen -S aztec -X stuff "aztec start --node --archiver --sequencer \\
  --network alpha-testnet \\
  --l1-rpc-urls $RPC_URL \\
  --l1-consensus-host-urls $BEACON_URL \\
  --sequencer.validatorPrivateKey $PRIVATE_KEY \\
  --sequencer.coinbase $PUBLIC_ADDRESS \\
  --p2p.p2pIp $SERVER_IP\n"
echo -e "${GREEN}Sequencer node started in screen session 'aztec'.${NC}"
echo -e "To reconnect to the session later, use: ${YELLOW}screen -r aztec${NC}"
echo -e "If disconnected, the node will continue running in the background."
confirm_step

# Step 7: Sync Node and Get Apprentice Role
print_header "Step 7: Sync Node and Earn Apprentice Role"
echo -e "Your node is now running and syncing. This may take a few minutes."
echo -e "${YELLOW}Wait at least 10-20 minutes for the node to sync before proceeding.${NC}"
echo -e "Navigate to the 'operators | start-here' channel in the Aztec Discord Server."
echo -e "To earn the Apprentice role, follow these steps after syncing:"
echo -e "\n1. Get the block number using this command:"
echo -e "${YELLOW}curl -s -X POST -H 'Content-Type: application/json' -d '{\"jsonrpc\":\"2.0\",\"method\":\"node_getL2Tips\",\"params\":[],\"id\":67}' http://localhost:8080 | jq -r '.result.proven.number'${NC}"
echo -e "Example output: 66666"
echo -e "\n2. Use the block number in this Nassh command to get the proof:"
echo -e "${YELLOW}curl -s -X POST -H 'Content-Type: application/json' -d '{\"jsonrpc\":\"2.0\",\"method\":\"node_getArchiveSiblingPath\",\"params\":[\"block-number\",\"block-number\"],\"id\":67}' http://localhost:8080 | jq -r \".result\"${NC}"
echo -e "Replace 'block-number' with the number from step 1."
echo -e "\n3. In the Discord 'operators | start-here' channel, run:"
echo -e "${YELLOW}/operator start${NC}"
echo -e "Provide your public address (${PUBLIC_ADDRESS}), block number, and proof when prompted."
echo -e "You should receive the Apprentice role instantly."
confirm_step

# Step 8: Display Validator Registration Command
print_header "Step 8: Register as Validator (Try Later)"
echo -e "Below is the command to register as a validator on the Aztec Network."
echo -e "${YELLOW}Important: If you see an error like 'Error: ValidatorQuotaFilledUntil', it means the validator quota is currently full. You will need to try again later after some time has passed (e.g., a few hours or the next day).${NC}"
echo -e "\nValidator Registration Command:"
echo -e "${YELLOW}aztec add-l1-validator \\"
echo -e "  --l1-rpc-urls $RPC_URL \\"
echo -e "  --private-key $PRIVATE_KEY \\"
echo -e "  --attester $PUBLIC_ADDRESS \\"
echo -e "  --proposer-eoa $PUBLIC_ADDRESS \\"
echo -e "  --staking-asset-handler 0xF739D03e98e23A7B65940848aBA8921fF3bAc4b2 \\"
echo -e "  --l1-chain-id 11155111${NC}"
echo -e "\n${YELLOW}Please save this command and run it later when the validator quota is available.${NC}"
echo -e "${GREEN}Setup complete! Your node is running. Follow Step 7 to earn the Apprentice role, and try the validator command above later.${NC}"
echo -e "To check your node, reconnect to the screen session with: ${YELLOW}screen -r aztec${NC}"
echo -e "Stay updated by following me on Twitter: ${YELLOW}https://x.com/0xCrypton_${NC}"
exit 0
