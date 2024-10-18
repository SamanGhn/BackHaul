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
  echo -e "${WHITE}    1) ${YELLOW}Tcp Configuration${RESET}"
  echo -e "${WHITE}    2) ${YELLOW}WS Configuration${RESET}"
  echo -e "${WHITE}    0) ${RED}Exit${RESET}"
  echo -e "${BLUE}--------------------------------------${RESET}"
}

# تابع برای اجرای TCP Configuration
run_tcp_configuration() {
  # فرض کنید که فایل TCP.sh در همین دایرکتوری ذخیره شده است
  echo -e "${GREEN}Running TCP Configuration...${RESET}"
  bash TCP.sh  # اجرای اسکریپت TCP.sh
  echo -e "${GREEN}TCP Configuration completed.${RESET}"
  sleep 2  # تاخیر کوتاه برای مشاهده نتیجه
}

# تابع برای اجرای WS Configuration
run_ws_configuration() {
  SCRIPT_URL="https://raw.githubusercontent.com/SamanGhn/BackHaul/main/ws.sh"  # فرض می‌کنیم اسکریپت مربوط به WS اینجا موجود است
  echo -e "${GREEN}Running WS Configuration...${RESET}"
  bash <(curl -Ls "$SCRIPT_URL")
  echo -e "${GREEN}WS Configuration completed.${RESET}"
  sleep 2  # تاخیر کوتاه برای مشاهده نتیجه
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
      run_tcp_configuration
      ;;
    2)
      run_ws_configuration
      ;;
    0)
      exit_program
      ;;
    *)
      echo -e "${RED}Invalid option. Please try again.${RESET}"
      sleep 1  # تاخیر کوتاه برای کاربر
      ;;
  esac
done
