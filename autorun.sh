#!/bin/bash

# آدرس فایل اسکریپت در GitHub (دسترسی به فایل خام)
SCRIPT_URL="https://raw.githubusercontent.com/SamanGhn/BackHaul/main/autoscripts.sh"

# دانلود و اجرای فایل اسکریپت
bash <(curl -Ls "$SCRIPT_URL")
