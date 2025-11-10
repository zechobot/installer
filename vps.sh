#!/bin/bash

# =============================
# Script Info VPS Ringkas
# =============================

# WARNA
GREEN="\e[32m"
YELLOW="\e[33m"
CYAN="\e[36m"
RED="\e[31m"
RESET="\e[0m"

echo -e "${CYAN}================ VPS INFO =================${RESET}"

# 1. OS
OS=$(uname -s) 
KERNEL=$(uname -r)
ARCH=$(uname -m)
echo -e "${GREEN}OS:${RESET} $OS, Kernel: $KERNEL, Arch: $ARCH"

# 2. CPU Info
CPU_MODEL=$(awk -F: '/model name/ {print $2; exit}' /proc/cpuinfo)
CPU_CORES=$(grep -c ^processor /proc/cpuinfo)
echo -e "${GREEN}CPU:${RESET} $CPU_MODEL, Cores: $CPU_CORES"

# 3. RAM
RAM_TOTAL=$(free -h | awk '/Mem:/ {print $2}')
RAM_USED=$(free -h | awk '/Mem:/ {print $3}')
RAM_FREE=$(free -h | awk '/Mem:/ {print $4}')
echo -e "${GREEN}RAM:${RESET} Total: $RAM_TOTAL, Used: $RAM_USED, Free: $RAM_FREE"

# 4. Disk
DISK_TOTAL=$(df -h / | awk 'NR==2 {print $2}')
DISK_USED=$(df -h / | awk 'NR==2 {print $3}')
DISK_AVAIL=$(df -h / | awk 'NR==2 {print $4}')
DISK_USE=$(df -h / | awk 'NR==2 {print $5}')
echo -e "${GREEN}Disk /:${RESET} Total: $DISK_TOTAL, Used: $DISK_USED, Free: $DISK_AVAIL (${DISK_USE})"

# 5. IP
PUB_IP=$(curl -s ifconfig.me)
LOCAL_IP=$(hostname -I | awk '{print $1}')
echo -e "${GREEN}IP:${RESET} Public: $PUB_IP, Local: $LOCAL_IP"

# 6. Uptime & Load
UPTIME_INFO=$(uptime -p)
LOAD=$(uptime | awk -F'load average:' '{print $2}' | sed 's/^[ \t]*//')
echo -e "${GREEN}Uptime:${RESET} $UPTIME_INFO"
echo -e "${GREEN}Load:${RESET} $LOAD"

# 7. Docker Info (jika ada)
if command -v docker &> /dev/null; then
    DOCKER_COUNT=$(docker ps -q | wc -l)
    echo -e "${GREEN}Docker containers running:${RESET} $DOCKER_COUNT"
fi

echo -e "${CYAN}===========================================${RESET}"
