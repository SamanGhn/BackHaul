#!/bin/bash

# Define tokens and tunnel ports
declare -a tokens=(
    "AxBhD3bbq4XxKcPc"
    "kDvFdjKnKRtOg9P9"
    "ZhZAq3zWSTSUW27z"
    "ud3aOH0PkRxuDzKt"
    "BlVIog7afZnknAJ2"
    "YVEGwYxJZRzulDGN"
    "IpC1Z2QB2QnURFX6"
    "14fKSboDD9JfduVO"
)

declare -a tunnel_ports=(
    "1010"
    "1111"
    "1212"
    "1313"
    "1414"
    "1515"
    "1616"
    "1717"
)

declare -a foreign_ports=(
    "8443,2083,2096,2053,2087,39324,33262,443"
    "8442,442,2086,2052"
    "51901,29442,37646,45546,25784,42224,13277,20250,32117,59887"
    "49669,37530,54370,50342"
    "2514,2614"
    "2515,2615"
    "2516,2616"
    "2517,2617"
)

# Fixed mux_session value for all servers
mux_session=6

# Function to install backhaul
install_backhaul() {
    echo "Installing backhaul..."

    # Initial setup for installing backhaul
    mkdir -p backhaul
    cd backhaul

    wget https://github.com/Musixal/Backhaul/releases/download/v0.1.1/backhaul_linux_amd64.tar.gz -O backhaul_linux.tar.gz
    tar -xf backhaul_linux.tar.gz
    rm backhaul_linux.tar.gz LICENSE README.md
    chmod +x backhaul
    mv backhaul /usr/bin/backhaul

    # Go back to the previous directory
    cd ..

    # Get server location from the user
    read -p "Is this server located in Iran? (y/n): " location 

    # If the server is located in Iran
    if [ "$location" == "y" ]; then
        echo "This server is located in Iran, applying settings for Iran..."

        # Get the number of foreign servers
        read -p "How many foreign servers do you have? " num_servers

        # Loop for each foreign server
        for ((i=0; i<num_servers; i++))
        do
            echo "Configuring foreign server number $((i + 1))..."

            # Get tunnel port and token based on index
            tunnelport=${tunnel_ports[i]}
            token=${tokens[i]}
            ports_input=${foreign_ports[i]}

            # Get the index of the foreign server
            read -p "Please enter the index (1-${num_servers}) of this foreign server: " server_index
            server_index=$((server_index - 1))  # Adjust for zero-based index

            # Create a config file for the Iran server with settings for each foreign server
            sudo tee /root/backhaul/config_$((i + 1)).toml > /dev/null <<EOL
[server]
bind_addr = "0.0.0.0:$tunnelport"
transport = "tcp"
token = "$token"
keepalive_period = 20
nodelay = false
channel_size = 2048
connection_pool = 8
mux_session = $mux_session

ports = [ 
$ports_input
]
EOL

            # Create a service file for the foreign server with a specific number (i)
            sudo tee /etc/systemd/system/backhaul_$((i + 1)).service > /dev/null <<EOL
[Unit]
Description=Backhaul Reverse Tunnel Service for Server $((i + 1))
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/backhaul -c /root/backhaul/config_$((i + 1)).toml
Restart=always
RestartSec=3
LimitNOFILE=1048576

[Install]
WantedBy=multi-user.target
EOL

            # Reload systemd, enable and start the service
            sudo systemctl daemon-reload
            sudo systemctl enable backhaul_$((i + 1)).service
            sudo systemctl start backhaul_$((i + 1)).service
            sudo systemctl status backhaul_$((i + 1)).service
        done

    # If the server is located outside Iran
    else
        echo "This server is located outside Iran, applying settings for outside..."

        # Get the IP of the Iran server from the user
        read -p "Please enter the IP address of the Iran server: " ip_iran

        # Get the foreign server index
        read -p "Which foreign server is this in relation to the Iran server? " server_index
        server_index=$((server_index - 1))  # Adjust for zero-based index

        # Get tunnel port and token based on index
        tunnelport=${tunnel_ports[server_index]}
        token=${tokens[server_index]}

        # Create a config file for the foreign server with the given index
        sudo tee /root/backhaul/config_$((server_index + 1)).toml > /dev/null <<EOL
[client]
remote_addr = "$ip_iran:$tunnelport"
transport = "tcp"
token = "$token"
keepalive_period = 20
nodelay = false
retry_interval = 1
mux_session = $mux_session
EOL

        # Create a service file for the foreign server with the given index
        sudo tee /etc/systemd/system/backhaul_$((server_index + 1)).service > /dev/null <<EOL
[Unit]
Description=Backhaul Reverse Tunnel Service for Server $((server_index + 1))
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/backhaul -c /root/backhaul/config_$((server_index + 1)).toml
Restart=always
RestartSec=3
LimitNOFILE=1048576

[Install]
WantedBy=multi-user.target
EOL

        # Reload systemd, enable and start the service
        sudo systemctl daemon-reload
        sudo systemctl enable backhaul_$((server_index + 1)).service
        sudo systemctl start backhaul_$((server_index + 1)).service
        sudo systemctl status backhaul_$((server_index + 1)).service
    fi
}

# Function to uninstall backhaul
uninstall_backhaul() {
    echo "Uninstalling backhaul..."

    # Stop and disable all backhaul services
    for service in /etc/systemd/system/backhaul_*.service; do
        sudo systemctl stop $(basename $service)
        sudo systemctl disable $(basename $service)
        sudo rm -f $service
    done

    # Remove the backhaul binary and config files
    sudo rm -rf /usr/bin/backhaul
    sudo rm -rf /root/backhaul

    echo "Backhaul has been successfully uninstalled."
}

# Function to update backhaul
update_backhaul() {
    echo "Updating backhaul..."
    # (Implementation for update can be added here if needed)
}

# Main menu loop
while true; do
    echo "---------------------------------"
    echo "  Backhaul Management Menu"
    echo "---------------------------------"
    echo "0) Exit"
    echo "1) Install Backhaul"
    echo "2) Uninstall Backhaul"
    echo "3) Update Backhaul"
    echo "---------------------------------"

    read -p "Please choose an option: " option

    case $option in
        0)
            echo "Exiting..."
            exit 0
            ;;
        1)
            install_backhaul
            ;;
        2)
            uninstall_backhaul
            ;;
        3)
            update_backhaul
            ;;
        *)
            echo "Invalid option, please try again."
            ;;
    esac
done
