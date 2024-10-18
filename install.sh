#!/bin/bash

# رنگ‌ها
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
WHITE='\033[1;37m'
RESET='\033[0m'  # برای بازگشت به حالت پیش‌فرض

# نمایش تیتر BackHaul Scripts
title() {
  echo -e "${CYAN}==============================${RESET}"
  echo -e "${GREEN}       BackHaul Scripts       ${RESET}"
  echo -e "${CYAN}==============================${RESET}"
}

# تابع برای نمایش منو
show_menu() {
  echo -e "${BLUE}--------------------------------------${RESET}"
  echo -e "${WHITE}    1) ${YELLOW}Install/Update Core${RESET}"
  echo -e "${WHITE}    2) ${YELLOW}Tcp Configuration${RESET}"
  echo -e "${WHITE}    3) ${YELLOW}WS Configuration${RESET}"
  echo -e "${WHITE}    4) ${YELLOW}Uninstall Backhaul${RESET}"
  echo -e "${WHITE}    0) ${RED}Exit${RESET}"
  echo -e "${BLUE}--------------------------------------${RESET}"
}

# تابع برای نصب یا بروزرسانی Core
install_update_core() {
  echo -e "${GREEN}Installing or Updating Backhaul Core...${RESET}"

  mkdir -p backhaul
  cd backhaul || { echo -e "${RED}Failed to change directory!${RESET}"; exit 1; }

  wget https://github.com/Musixal/Backhaul/releases/download/v0.6.0/backhaul_linux_amd64.tar.gz -O backhaul_linux.tar.gz
  tar -xf backhaul_linux.tar.gz
  rm backhaul_linux.tar.gz LICENSE README.md
  chmod +x backhaul
  mv backhaul /usr/bin/backhaul

  echo -e "${GREEN}Core installation/update completed.${RESET}"
  cd ..
  sleep 2  # تاخیر کوتاه برای مشاهده نتیجه
}

# تابع برای اجرای TCP Configuration
run_tcp_configuration() {
  echo -e "${GREEN}Running TCP Configuration...${RESET}"
  
  # اجرای اسکریپت TCP.sh از گیت‌هاب
  bash <(curl -Ls https://raw.githubusercontent.com/SamanGhn/BackHaul/main/TCP.sh)
  
  echo -e "${GREEN}TCP Configuration completed.${RESET}"
  sleep 2  # تاخیر کوتاه برای مشاهده نتیجه
}

# تابع برای اجرای WS Configuration
run_ws_configuration() {
  echo -e "${GREEN}Running WS Configuration...${RESET}"
  
  # اجرای اسکریپت WS.sh از گیت‌هاب (فرض می‌کنیم آدرس درست باشد)
  bash <(curl -Ls https://raw.githubusercontent.com/SamanGhn/BackHaul/main/ws.sh)
  
  echo -e "${GREEN}WS Configuration completed.${RESET}"
  sleep 2  # تاخیر کوتاه برای مشاهده نتیجه
}

# تابع برای Uninstall Backhaul
uninstall_backhaul() {
    echo "Uninstalling backhaul..."

    # Stop and disable all backhaul services
    for service_file in /etc/systemd/system/backhaul_*.service; do
        if [ -f "$service_file" ]; then
            service_name=$(basename "$service_file")
            sudo systemctl stop $service_name
            sudo systemctl disable $service_name
            sudo rm "$service_file"
            echo "Removed service file: $service_file"
            
            # Reload systemd and reset failed services after each service is removed
            sudo systemctl daemon-reload
            sudo systemctl reset-failed
        fi
    done

    # Remove backhaul binary and config files
    if [ -f /usr/bin/backhaul ]; then
        sudo rm /usr/bin/backhaul
        echo "Removed /usr/bin/backhaul"
    fi

    if [ -d /root/backhaul ]; then
        sudo rm -rf /root/backhaul
        echo "Removed /root/backhaul directory"
    fi

    # Reload systemd to apply changes
    sudo systemctl daemon-reload
    sudo systemctl reset-failed

    # Ask the user if they want to remove logs and additional settings
    read -p "Do you want to remove logs and additional settings (log_level, web_port, sniffer_log)? (y/n): " remove_logs

    if [ "$remove_logs" == "y" ]; then
        echo "Removing logs and additional configuration settings..."

        # Remove log files
        if [ -f /root/backhaul.json ]; then
            sudo rm /root/backhaul.json
            echo "Removed /root/backhaul.json"
        fi

        # Loop through all remaining configuration files and remove log_level, web_port, and sniffer_log
        for config_file in /root/backhaul/config_*.toml; do
            if [ -f "$config_file" ]; then
                sudo sed -i '/log_level/d' "$config_file"
                sudo sed -i '/web_port/d' "$config_file"
                sudo sed -i '/sniffer_log/d' "$config_file"
                echo "Removed log_level, web_port, and sniffer_log from $config_file"
            fi
        done

        echo "Logs and additional settings removed."
    fi

    echo "Backhaul uninstalled successfully."
}

# تابع برای خروج
exit_program() {
  echo -e "${RED}Exiting...${RESET}"
  exit 0
}

# حلقه اصلی
while true; do
  clear  # پاک کردن صفحه برای نمایش لوگو و منو هر بار از ابتدا
  title
  show_menu
  read -p "Choose an option: " choice
  case $choice in
    1)
      install_update_core  # نصب یا بروزرسانی Core
      ;;
    2)
      run_tcp_configuration  # انتخاب TCP
      ;;
    3)
      run_ws_configuration  # انتخاب WS
      ;;
    4)
      uninstall_backhaul  # Uninstall Backhaul
      ;;
    0)
      exit_program  # خروج
      ;;
    *)
      echo -e "${RED}Invalid option. Please try again.${RESET}"
      sleep 1  # تاخیر کوتاه برای کاربر
      ;;
  esac
done
