#!/bin/bash

COLORS=$(tput setaf 3)
RESET=$(tput sgr0)

# ============================================
echo -e "\033[1;33m"
echo "████████╗████████╗████████╗"
echo "╚══██╔══╝╚══██╔══╝╚══██╔══╝"
echo "   ██║      ██║      ██║   "
echo "   ██║      ██║      ██║   "
echo "   ██║      ██║      ██║   "
echo "   ╚═╝      ╚═╝      ╚═╝   "
echo "          TTT Labs         " 
echo -e "\033[0m" 

echo -e "\033[1;32m"
echo "This tool simplifies the installation, management, and"
echo "operation of your Story Validator Node with ease. 🚀"
echo -e "\033[0m"
# ============================================

install_dependencies() {
    echo -e "${COLORS}🚀 Updating packages and installing dependencies...${RESET}"
    sudo apt update && sudo apt upgrade -y
    sudo apt install -y curl tar wget clang pkg-config libssl-dev libleveldb-dev jq \
        build-essential bsdmainutils git make ncdu htop screen unzip bc fail2ban \
        tmux lz4 gcc unzip
    echo -e "${COLORS}✅ Dependencies installed successfully!${RESET}"
}

install_go() {
    local GO_VERSION="1.22.3"
    echo -e "${COLORS}🚀 Installing Go...${RESET}"
    cd $HOME && sudo rm -rf /usr/local/go
    wget -q "https://golang.org/dl/go${GO_VERSION}.linux-amd64.tar.gz"
    sudo tar -C /usr/local -xzf go${GO_VERSION}.linux-amd64.tar.gz
    rm go${GO_VERSION}.linux-amd64.tar.gz

    echo "export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin" >> ~/.bash_profile
    source ~/.bash_profile
    mkdir -p ~/go/bin
    go version
    echo -e "${COLORS}✅ Go installed successfully!${RESET}"

}

install_binaries() {
    echo -e "${COLORS}🚀 Installing Story and Geth binaries...${RESET}"
    rm -rf $HOME/story && git clone https://github.com/piplabs/story.git
    cd $HOME/story && git checkout v0.11.0 && go build -o story ./client

    mkdir -p $HOME/.story/story/cosmovisor/genesis/bin
    mv story $HOME/.story/story/cosmovisor/genesis/bin/
    sudo ln -sf $HOME/.story/story/cosmovisor/genesis $HOME/.story/story/cosmovisor/current
    sudo ln -sf $HOME/.story/story/cosmovisor/current/bin/story /usr/local/bin/story

    rm -rf $HOME/story-geth && git clone https://github.com/piplabs/story-geth.git
    cd story-geth && git checkout v0.9.4 && make geth
    sudo mv build/bin/geth /usr/local/bin/
    echo -e "${COLORS}✅ Story and Geth binaries installed successfully!${RESET}"
}

setup_services() {
    echo -e "${COLORS}🚀 Setting up systemd services...${RESET}"

    sudo tee /etc/systemd/system/story-geth.service > /dev/null <<EOF
[Unit]
Description=Story Geth Client
After=network.target

[Service]
User=$USER
ExecStart=/usr/local/bin/geth --iliad --syncmode full --http --http.api eth,net,web3 --http.port 8545
Restart=on-failure
LimitNOFILE=4096

[Install]
WantedBy=multi-user.target
EOF

    sudo tee /etc/systemd/system/story.service > /dev/null <<EOF
[Unit]
Description=Story Consensus Client
After=network.target

[Service]
User=$USER
WorkingDirectory=$HOME/.story/story
ExecStart=/usr/local/bin/story run
Restart=on-failure
LimitNOFILE=4096

[Install]
WantedBy=multi-user.target
EOF

    sudo systemctl daemon-reload
    sudo systemctl enable --now story-geth story
    echo -e "${COLORS}✅ Setting up systemd services successfully!${RESET}"

}
configure_story_node() {
    echo "🚀 Story node configuring...."
    story init --network "$CHAIN_ID" --moniker "$Validator_Name"
    if [[ "$change_ports" == "y" ]]; then
        sed -i "s/tcp:\/\/127\.0\.0\.1:26658/tcp:\/\/127.0.0.1:${proxy_app_prefix}658/" \
            $HOME/.story/story/config/config.toml
        sed -i "s/tcp:\/\/127\.0\.0\.1:26657/tcp:\/\/127.0.0.1:${rpc_prefix}657/" \
            $HOME/.story/story/config/config.toml
        sed -i "s/tcp:\/\/0\.0\.0\.0:26656/tcp:\/\/0.0.0.0:${p2p_prefix}656/" \
            $HOME/.story/story/config/config.toml

        echo "Ports have been updated to ${proxy_app_prefix}658, ${rpc_prefix}657, and ${p2p_prefix}656."
    fi
    wget -O $HOME/.story/story/config/genesis.json \
        https://snapshots.tienthuattoan.com/testnet/story/genesis.json
    wget -O $HOME/.story/story/config/addrbook.json \
        https://snapshots.tienthuattoan.com/testnet/story/addrbook.json

    sed -i -e "s|^seeds *=.*|seeds = \"269caa385a94f551bd7550093c64d724680bcdeb@story-testnet-rpc.tienthuattoan.com:30656\"|" \
        $HOME/.story/story/config/config.toml

    echo "✅ Story node configuration completed successfully."
}

install_node() {
    echo -e "${COLORS}Let's begin install Story Node${RESET}"
    read -p $'\e[1m\e[32mEnter your Validator_Name: \e[0m' Validator_Name

    echo export Validator_Name=${Validator_Name} >> $HOME/.bash_profile
    echo export CHAIN_ID="iliad" >> $HOME/.bash_profile
    source ~/.bash_profile

    read -p $'\e[1m\e[32mDo you want to change the default ports? (yes[y]/no[n]):\e[0m' change_ports
    change_ports=$(echo "$change_ports" | tr '[:upper:]' '[:lower:]')

    if [[ "$change_ports" == "yes" || "$change_ports" == "y" ]]; then
        read -p "Enter the new first two digits for the proxy_app port (26658): " proxy_app_prefix
        read -p "Enter the new first two digits for the rpc port (26657): " rpc_prefix
        read -p "Enter the new first two digits for the p2p port (26656): " p2p_prefix

        if ! [[ "$proxy_app_prefix" =~ ^[0-9]{2}$ ]] || 
           ! [[ "$rpc_prefix" =~ ^[0-9]{2}$ ]] || 
           ! [[ "$p2p_prefix" =~ ^[0-9]{2}$ ]]; then
            echo "Invalid input. Ports will not be changed."
            change_ports="n"
        fi
    fi
}

create_wallet() {
    read -p $'\e[1m\e[35m Your WalletName:\e[0m' Wallet
    echo "export Wallet=${Wallet}" >> ~/.bash_profile
    source ~/.bash_profile
    story validator export --export-evm-key
    echo -e "${COLORS}!!!!SAVE YOUR PRIVATE KEY!!!!${RESET}"
}

check_wallet_info() {
    story validator export
}

check_wallet_balance() {
    read -p "Enter your EVM Address: " evm_address
    balance=$(geth --exec "eth.getBalance('$evm_address')" attach ~/.story/geth/iliad/geth.ipc)
    balance_eth=$(awk "BEGIN {printf \"%.18f\", $balance/1000000000000000000}")
    echo "Balance: $balance_eth IP"
}

check_sync_info() {
    local rpc_port=$(sed -n '/\[rpc\]/,/laddr/ { /laddr/ {s/.*://; s/".*//; p} }' ~/.story/story/config/config.toml)
    curl -s http://localhost:$rpc_port/status | jq .result.sync_info
}

check_sync_status() {
    local rpc_port=$(sed -n '/\[rpc\]/,/laddr/ { /laddr/ {s/.*://; s/".*//; p} }' ~/.story/story/config/config.toml)
    while true; do
        local_height=$(curl -s localhost:$rpc_port/status | jq -r '.result.sync_info.latest_block_height')
        network_height=$(curl -s https://story-testnet-rpc.tienthuattoan.com/status | jq -r '.result.sync_info.latest_block_height')
        blocks_left=$((network_height - local_height))
        estimated_time=$(echo "$blocks_left * 2.80" | bc)
        hours=$(echo "$estimated_time / 3600" | bc)
        minutes=$(echo "($estimated_time % 3600) / 60" | bc)

        echo -e "\033[1;38mYour height:\033[0m \033[1;32m$local_height\033[0m | \033[1;35mNetwork height:\033[0m \033[1;36m$network_height\033[0m | \033[1;29mBlocks left:\033[0m \033[1;31m$blocks_left\033[0m | \033[1;33mEstimated time: $hours hours $minutes minutes\033[0m"
        sleep 5
    done
    }


check_validator_info() {
    local rpc_port=$(sed -n '/\[rpc\]/,/laddr/ { /laddr/ {s/.*://; s/".*//; p} }' ~/.story/story/config/config.toml)
    curl localhost:$rpc_port/status | jq
}

sync_snapshot() {
    local auto_confirm=$1 
    if [[ "$auto_confirm" != "yes" ]]; then
        read -p "Do you want to synchronize via snapshot? (yes/no): " user_choice
        user_choice=$(echo "$user_choice" | tr '[:upper:]' '[:lower:]')
    else
        user_choice="yes"
    fi
    if [[ "$user_choice" == "yes" ]]; then
        echo "🚀 Synchronizing via snapshot..."
		
        sudo systemctl stop story story-geth
        rm -rf $HOME/.story/geth/iliad/geth/chaindata
		mkdir -p $HOME/.story/geth/iliad/geth
		curl -o - -L https://snapshots.tienthuattoan.com/testnet/story/story_geth_latest.tar.lz4 | lz4 -c -d - | tar -x -C ~/.story/geth/iliad/geth/
	
		rm -rf $HOME/.story/story/data
        curl -o - -L https://snapshots.tienthuattoan.com/testnet/story/story_latest.tar.lz4 | lz4 -c -d - | tar -x -C ~/.story/story/        
        sudo systemctl restart story-geth
        sudo systemctl restart story
    else
        echo "Synchronization cancelled."
    fi
    echo -e "${COLORS}✅ Synchronizing via snapshot successfully${RESET}"
}

check_version() {
    YELLOW='\033[1;33m'
    BLUE='\033[1;34m'
    RESET='\033[0m'
    echo -e "${YELLOW}Story Version:${RESET}"
    story version
    echo -e "${BLUE}Geth Version:${RESET}"
    geth version | head -n 4
}

restart_story_node() {
    echo -e "${COLORS}🔄 Restarting Story and Geth services...${RESET}"
    sudo systemctl restart story story-geth
    echo -e "${COLORS}✅ Story and Geth services restarted successfully!${RESET}"
    sudo journalctl -fu story -ocat
}

stop_story_node() {
    echo -e "${COLORS}✋🏼 Stop Story and Geth services...${RESET}"
    sudo systemctl stop story story-geth
    echo -e "${COLORS}✅ Story and Geth services restarted successfully!${RESET}"
}

delete_node() {
    read -p "Are you sure you want to delete the node? (yes/no): " confirmation
    if [[ "$confirmation" == "yes" ]]; then
        echo "🚀 Node deleting..."
        sudo systemctl stop story-geth story
        sudo systemctl disable story-geth story
        sudo rm /etc/systemd/system/story-geth.service /etc/systemd/system/story.service
        sudo systemctl daemon-reload

        rm -rf ~/.story story story-geth $(which story) $(which geth)
        echo "${COLORS}✅ Node deleted successfully.${RESET}"
    else
        echo "Node deletion cancelled."
    fi
}

update_seed() {
    CONFIG_FILE="$HOME/.story/story/config/config.toml"
    echo -e "\033[1;35mPlease enter the new seed (format: node_id@ip:port):\033[0m"
    read -p "New seed: " new_seed
    if [[ -z "$new_seed" ]]; then
        echo -e "\033[1;31m⚠️ Seed cannot be empty. Operation cancelled.\033[0m"
        return 1
    fi
    echo "Updating seed in $CONFIG_FILE..."
    sed -i -e "s|^seeds *=.*|seeds = \"$new_seed\"|" "$CONFIG_FILE"

    if grep -q "seeds = \"$new_seed\"" "$CONFIG_FILE"; then
        echo -e "\033[1;32m✅ Seed updated successfully to: $new_seed\033[0m"
    else
        echo -e "\033[1;31m⚠️ Failed to update seed. Please check the configuration file.\033[0m"
    fi
}

update_fresh_peers() {
    PEERS_API_URL="https://story-testnet-rpc.tienthuattoan.com/net_info?"
    CONFIG_FILE="$HOME/.story/story/config/config.toml"
    echo "Fetching live peers from $PEERS_API_URL..."
    # Extract peer IDs and addresses from the API response
    PEERS=$(curl -s $PEERS_API_URL | jq -r '.result.peers[] | "\(.node_info.id)@\(.remote_ip):\(.node_info.listen_addr | split(":")[-1])"' | paste -sd, -)
    echo "$PEERS"
    if [ -n "$PEERS" ]; then
        echo "Updating persistent_peers in $CONFIG_FILE..."
        sed -i "/^\[p2p\]/,/^\[/{s/^[[:space:]]*persistent_peers *=.*/persistent_peers = \"$PEERS\"/}" "$CONFIG_FILE"
        echo -e "${COLORS}✅ Peers updated successfully.${RESET}"
    else
        echo "Failed to retrieve live peers or no peers available."
    fi
}

clear_persistent_peers() {
    CONFIG_FILE="$HOME/.story/story/config/config.toml"
    echo "Clearing all persistent_peers from $CONFIG_FILE..."

    # Use sed to remove the persistent_peers entry from the config file
    sed -i "/^\[p2p\]/,/^\[/{s/^[[:space:]]*persistent_peers *=.*/persistent_peers = \"\"/}" "$CONFIG_FILE"

    if grep -q 'persistent_peers = ""' "$CONFIG_FILE"; then
        echo -e "${MAGENTA}✅ persistent_peers cleared successfully.${RESET}"
    else
        echo "⚠️ Failed to clear persistent_peers."
    fi
}

help_menu() {
    echo -e "\033[1;34m========== HELP MENU ==========\033[0m"
    
    echo -e "\033[1;33m1) Install Story Node:\033[0m"
    echo "   - Installs and fully configures the Story Node from scratch."
    echo "   - Includes steps: installing dependencies, Go, downloading binaries, and setting up services."
    echo

    echo -e "\033[1;33m2) Check Story logs:\033[0m"
    echo "   - Displays the real-time logs of the Story Node service."
    echo

    echo -e "\033[1;33m3) Check Geth logs:\033[0m"
    echo "   - Displays the real-time logs of the Geth service."
    echo

    echo -e "\033[1;33m4) Check sync status:\033[0m"
    echo "   - Checks the synchronization status of the Story Node with the blockchain."
    echo "   - Displays block height and remaining blocks for sync completion."
    echo

    echo -e "\033[1;33m5) Check sync info:\033[0m"
    echo "   - Provides detailed sync information, including latest block and sync status."
    echo

    echo -e "\033[1;33m6) Check validator info:\033[0m"
    echo "   - Displays information about the validator, including status and ID."
    echo

    echo -e "\033[1;33m7) Synchronization via SnapShot:\033[0m"
    echo "   - Synchronizes the node using the latest snapshot to save time."
    echo

    echo -e "\033[1;33m8) Update new seed:\033[0m"
    echo "   - Prompts the user to enter a new seed and updates the configuration file."
    echo

    echo -e "\033[1;33m9) Sync new live-peers:\033[0m"
    echo "   - Fetches live peers from the server and updates the persistent peers in the configuration."
    echo

    echo -e "\033[1;33m10) Clear persistent peers:\033[0m"
    echo "   - Clears all persistent peers from the configuration file."
    echo

    echo -e "\033[1;33m11) Check Story Version:\033[0m"
    echo "   - Displays the current version of the Story Node and Geth."
    echo

    echo -e "\033[1;33m12) Upgrade Story version:\033[0m"
    echo "   - Downloads and installs the latest Story binaries."
    echo

    echo -e "\033[1;33m13) Create wallet:\033[0m"
    echo "   - Creates a new wallet and exports the private key."
    echo

    echo -e "\033[1;33m14) Check wallet info:\033[0m"
    echo "   - Displays information about the created wallet."
    echo

    echo -e "\033[1;33m15) Check wallet balance:\033[0m"
    echo "   - Checks the balance of the wallet using the EVM address."
    echo

    echo -e "\033[1;33m16) Restart Story Node:\033[0m"
    echo "   - Restarts the Story Node service."
    echo

    echo -e "\033[1;33m17) Stop Story Node:\033[0m"
    echo "   - Stops the Story Node service."
    echo

    echo -e "\033[1;33m18) Delete Story Node:\033[0m"
    echo "   - Stops, disables, and removes the Story Node and its data."
    echo

    echo -e "\033[1;33m19) Help:\033[0m"
    echo "   - Displays this help menu."
    echo

    echo -e "\033[1;33m20) Exit:\033[0m"
    echo "   - Exits the program."
    echo

    echo -e "\033[1;34m===============================\033[0m"
}


# ============================================
# Main Menu
# ============================================

menu() {
    PS3="Select an action: "
    options=(
        "Install Story node" "Check Story logs" "Check Geth logs" "Check sync status" "Check sync info" "Check validator info" "Synchronization via snapshot" "Update new seed" "Sync new live-peers" "Clear persistent peers" "Check Story version" "Upgrade Story version" "Create new wallet" "Check wallet info" "Check wallet balance" "Restart Story node" "Stop Story node" "Delete Story node" "Help" "Exit"
    )

    select opt in "${options[@]}"; do
        case $opt in
            "Install Story node") install_node; install_dependencies; install_go; install_binaries; setup_services; configure_story_node; sync_snapshot yes; sudo journalctl -fu story -ocat ;;
            "Check Story logs") sudo journalctl -fu story -ocat ;;
            "Check Geth logs") sudo journalctl -fu story-geth -ocat ;;
            "Check sync status") check_sync_status ;;
            "Check sync info") check_sync_info ;;
            "Check validator info") check_validator_info ;;
            "Create new wallet") create_wallet ;;
            "Check wallet info") check_wallet_info ;;
            "Check wallet balance") check_wallet_balance ;;
            "Update new seed") update_seed ;;
            "Sync new live-peers") update_fresh_peers ;;
            "Clear persistent peers") clear_persistent_peers ;;
            "Check Story version") check_version ;;
            "Synchronization via snapshot") sync_snapshot ;;
            "Upgrade Story version") install_binaries ;;
            "Delete Story node") delete_node ;;
            "Restart Story node") restart_story_node ;;
            "Stop Story node") stop_story_node ;;
            "Help") help_menu ;;
            "Exit") exit ;;
            *) echo "Invalid option. Try again." ;;
        esac
    done
}

menu
