#!/bin/bash

# Color Definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
RESET='\033[0m'

# Function to set backhaul configuration
set_backhaul_config() {
    echo -e "${CYAN}---------------------------------${RESET}"
    echo -e "${GREEN}Setting up backhaul configuration...${RESET}"
    echo -e "${CYAN}---------------------------------${RESET}"

    # Get server location from the user
    read -p "Is this server located in Iran? (y/n): " location 
    echo ""

    # If the server is located in Iran
    if [ "$location" == "y" ]; then
        echo -e "${GREEN}This server is located in Iran, applying settings for Iran...${RESET}"
        echo ""

        # Get the number of foreign servers
        read -p "How many foreign servers do you have? " num_servers
        echo ""

        # Loop for each foreign server
        for ((i=1; i<=num_servers; i++)); do
            echo -e "${GREEN}Configuring foreign server number $i...${RESET}"
            echo ""

            # Get tunnel port, token, and other details from the user for each server
            read -p "Enter the tunnel port number for foreign server $i: " tunnelport
            read -p "Please enter the token for foreign server $i: " token
            read -p "Do you want to enable nodelay? (true/false): " nodelay
            read -p "Please enter the web port for foreign server $i: " web_port
            echo ""

            # Choose how to input ports (manual or range)
            read -p "Do you want to enter the ports manually or as a range? (m/r): " method
            echo ""

            if [ "$method" == "m" ]; then
                read -p "Do you want to specify separate input and output ports? (y/n): " separate_ports
                echo ""

                if [ "$separate_ports" == "y" ]; then
                    read -p "Please enter the input ports as a comma-separated list (e.g., 2020,2021,2027): " input_ports
                    read -p "Please enter the output ports as a comma-separated list (e.g., 3020,3021,3027): " output_ports
                    echo ""

                    IFS=',' read -r -a input_ports_array <<< "$input_ports"
                    IFS=',' read -r -a output_ports_array <<< "$output_ports"

                    ports_list=()

                    for ((j=0; j<${#input_ports_array[@]}; j++)); do
                        input_port="${input_ports_array[j]}"
                        output_port="${output_ports_array[j]}"
                        ports_list+=("\"$input_port=$output_port\"")
                    done
                else
                    read -p "Please enter all the ports as a comma-separated list (e.g., 2020,2021,2027): " port_list_input
                    echo ""
                    IFS=',' read -r -a ports_array <<< "$port_list_input"
                    ports_list=()

                    for port in "${ports_array[@]}"; do
                        ports_list+=("\"$port=$port\"")
                    done
                fi
            elif [ "$method" == "r" ]; then
                read -p "Please enter the start port: " start_port
                read -p "Please enter the end port: " end_port
                echo ""
                read -p "Do you want to specify separate input and output ports for the range? (y/n): " separate_ports

                if [ "$separate_ports" == "y" ]; then
                    read -p "Please enter the start output port: " start_output_port
                    read -p "Please enter the end output port: " end_output_port
                    echo ""

                    ports_list=()
                    for ((in_port=start_port, out_port=start_output_port; in_port<=end_port; in_port++, out_port++)); do
                        ports_list+=("\"$in_port=$out_port\"")
                    done
                else
                    ports_list=()
                    for ((port=start_port; port<=end_port; port++)); do
                        ports_list+=("\"$port=$port\"")
                    done
                fi
            else
                echo -e "${RED}Invalid input method. Please enter 'm' for manually or 'r' for range.${RESET}"
                exit 1
            fi

            ports_string=$(IFS=,; echo "${ports_list[*]}")

            # Create config file for each server
            sudo tee /root/backhaul/config_$i.toml > /dev/null <<EOL
[server]
bind_addr = "0.0.0.0:$tunnelport"
transport = "tcp"
accept_udp = false
token = "$token"
keepalive_period = 75
nodelay = $nodelay
heartbeat = 40
channel_size = 2048
sniffer = false
web_port = $web_port
sniffer_log = "/root/backhaul.json"
log_level = "info"
ports = [ 
$ports_string
]
EOL

            # Create service file for each server
            sudo tee /etc/systemd/system/backhaul_$i.service > /dev/null <<EOL
[Unit]
Description=Backhaul Reverse Tunnel Service for Server $i
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/backhaul -c /root/backhaul/config_$i.toml
Restart=always
RestartSec=3
LimitNOFILE=1048576

[Install]
WantedBy=multi-user.target
EOL

            # Start the service for each server
            sudo systemctl daemon-reload
            sudo systemctl enable backhaul_$i.service
            sudo systemctl start backhaul_$i.service
            sudo systemctl status backhaul_$i.service
            echo -e "${GREEN}Foreign server $i configured successfully!${RESET}"
            echo ""
        done

    # If the server is located outside Iran
    else
        echo -e "${GREEN}This server is located outside Iran, applying settings for outside...${RESET}"
        echo ""

        # Get the IP of the Iran server from the user
        read -p "Please enter the IP address of the Iran server: " ip_iran
        echo ""

        # Get the foreign server index
        read -p "Which foreign server is this in relation to the Iran server? " server_index
        echo ""

        # Get tunnel port for the foreign server
        read -p "Enter the tunnel port number for foreign server $server_index: " tunnelport
        echo ""

        # Get token for the foreign server
        read -p "Please enter the token for foreign server $server_index: " token
        echo ""

        # Get nodelay value from user
        read -p "Do you want to enable nodelay? (true/false): " nodelay
        echo ""

        # Get web port from user
        read -p "Please enter the web port for foreign server $server_index: " web_port
        echo ""

        # Create a config file for the foreign server with the given index
        sudo tee /root/backhaul/config_$server_index.toml > /dev/null <<EOL
[client]
remote_addr = "$ip_iran:$tunnelport"
transport = "tcp"
token = "$token"
connection_pool = 8
keepalive_period = 75
dial_timeout = 10
nodelay = $nodelay
retry_interval = 3
sniffer = false
web_port = $web_port
sniffer_log = "/root/backhaul.json"
log_level = "info"
EOL

        # Create a service file for the foreign server with the given index
        sudo tee /etc/systemd/system/backhaul_$server_index.service > /dev/null <<EOL
[Unit]
Description=Backhaul Reverse Tunnel Service for Server $server_index
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/backhaul -c /root/backhaul/config_$server_index.toml
Restart=always
RestartSec=3
LimitNOFILE=1048576

[Install]
WantedBy=multi-user.target
EOL

        # Reload systemd, enable and start the service
        sudo systemctl daemon-reload
        sudo systemctl enable backhaul_$server_index.service
        sudo systemctl start backhaul_$server_index.service
        sudo systemctl status backhaul_$server_index.service
        echo -e "${GREEN}Foreign server $server_index configured successfully!${RESET}"
        echo ""
    fi
}

# Function to edit backhaul configuration
edit_backhaul() {
    echo -e "${CYAN}---------------------------------${RESET}"
    echo -e "${GREEN}  Backhaul Edit Menu${RESET}"
    echo -e "${CYAN}---------------------------------${RESET}"
    echo ""
    echo -e "${YELLOW}1) Edit Token${RESET}"
    echo -e "${YELLOW}2) Add Ports${RESET}"
    echo -e "${YELLOW}3) Remove Ports${RESET}"
    echo -e "${YELLOW}4) Change Server Address${RESET}"
    echo -e "${YELLOW}0) Back to Configuration menu${RESET}"
    echo -e "${CYAN}---------------------------------${RESET}"
    
    read -p "Please choose an option: " edit_option

    case $edit_option in
        1)
            echo "Editing Token..."
            # Add your code to edit token here
            ;;
        2)
            echo "Adding Ports..."
            # Add your code to add ports here
            ;;
        3)
            echo "Removing Ports..."
            # Add your code to remove ports here
            ;;
        4)
            echo "Changing Server Address..."
            # Add your code to change server address here
            ;;
        0)
            echo -e "${GREEN}Returning to the main menu...${RESET}"
            return
            ;;
        *)
            echo -e "${RED}Invalid option, please try again.${RESET}"
            ;;
    esac
}

# Main Menu
while true; do
    echo -e "${CYAN}---------------------------------${RESET}"
    echo -e "${GREEN}       Backhaul Configuration${RESET}"
    echo -e "${CYAN}---------------------------------${RESET}"
    echo ""
    echo -e "${YELLOW}1) Set Backhaul Configuration${RESET}"
    echo -e "${YELLOW}2) Edit Backhaul Configuration${RESET}"
    echo -e "${YELLOW}0) Back to main menu${RESET}"
    echo -e "${CYAN}---------------------------------${RESET}"
    
    read -p "Please choose an option: " option

    case $option in
        1)
            set_backhaul_config
            ;;
        2)
            edit_backhaul
            ;;
        0)
            echo -e "${GREEN}Returning to the main menu...${RESET}"
            continue
            ;;
        *)
            echo -e "${RED}Invalid option, please try again.${RESET}"
            ;;
    esac
done
