#!/bin/bash

# تابع برای نمایش منو
show_menu() {
  echo "1) TCP Configuration"
  echo "2) WS Configuration"
  echo "3) Exit"
}

# تابع برای اجرای TCP Configuration
run_tcp_configuration() {
  SCRIPT_URL="https://raw.githubusercontent.com/SamanGhn/BackHaul/main/TCP.sh"
  echo "Running TCP Configuration..."
  bash <(curl -Ls "$SCRIPT_URL")
}

# تابع برای اجرای WS Configuration
run_ws_configuration() {
  SCRIPT_URL="https://raw.githubusercontent.com/SamanGhn/BackHaul/main/ws.sh"  # فرض می‌کنیم اسکریپت مربوط به WS اینجا موجود است
  echo "Running WS Configuration..."
  bash <(curl -Ls "$SCRIPT_URL")
}

# تابع برای خروج
exit_program() {
  echo "Exiting..."
  exit 0
}

# حلقه اصلی
while true; do
  show_menu
  read -p "Choose an option: " choice
  case $choice in
    1)
      run_tcp_configuration
      ;;
    2)
      run_ws_configuration
      ;;
    3)
      exit_program
      ;;
    *)
      echo "Invalid option. Please try again."
      ;;
  esac
done
