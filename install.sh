#!/bin/bash

# آدرس فایل اسکریپت در GitHub
SCRIPT_URL="https://raw.githubusercontent.com/SamanGhn/BackHaul/main/setup.sh"

# دانلود و اجرای فایل اسکریپت
bash <(curl -Ls "$SCRIPT_URL")
