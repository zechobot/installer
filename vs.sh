#!/usr/bin/env bash
# vps_info_monitor.sh
# Info sistem + monitoring "heavy user" & potensi DDoS indicators
# Run as root for most complete output: sudo ./vps_info_monitor.sh

GREEN="\e[32m"
YELLOW="\e[33m"
CYAN="\e[36m"
RED="\e[31m"
RESET="\e[0m"

echo -e "${CYAN}=========== VPS INFO & MONITOR ==========${RESET}"
echo -e "${GREEN}Time:${RESET} $(date -R)"
echo

# Basic system info
echo -e "${GREEN}OS/Kernel:${RESET} $(cat /etc/os-release 2>/dev/null | grep -E '^PRETTY_NAME' | cut -d= -f2 | tr -d '\"' || uname -a)"
echo -e "${GREEN}Uptime:${RESET} $(uptime -p)"
echo

# Disk/RAM/CPU summary
echo -e "${GREEN}Disk /:${RESET} $(df -h / | awk 'NR==2{print $2, \"total, used:\" $3, \"avail:\" $4, \"(\"$5\")\" }')"
echo -e "${GREEN}RAM:${RESET} $(free -h | awk '/Mem:/ {print $2 \" total, used:\" $3 \", free:\" $4}')"
echo -e "${GREEN}Load avg:${RESET} $(uptime | awk -F'load average:' '{print $2}' | sed 's/^ *//')"
echo

# Top processes by CPU and MEM
echo -e "${YELLOW}Top 8 processes by CPU:${RESET}"
ps -eo pid,ppid,cmd,%mem,%cpu,user --sort=-%cpu | head -n 9
echo

echo -e "${YELLOW}Top 8 processes by MEM:${RESET}"
ps -eo pid,ppid,cmd,%mem,%cpu,user --sort=-%mem | head -n 9
echo

# Aggregate resource usage per user
echo -e "${YELLOW}Per-user resource usage (CPU% and MEM% totals):${RESET}"
# Show users with non-zero usage, sorted by CPU
ps -eo user,%cpu,%mem --no-headers | \
  awk '{cpu[$1]+=$2; mem[$1]+=$3} END {for (u in cpu) printf "%-15s CPU:%6.2f%% MEM:%6.2f%%\n", u, cpu[u], mem[u]}' | \
  sort -k2 -nr | head -n 20
echo

# Users with many processes (possible runaway)
echo -e "${YELLOW}Top users by process count:${RESET}"
ps -eo user= | sort | uniq -c | sort -rn | head -n 20
echo

# Show processes with most open file descriptors / sockets (requires lsof)
if command -v lsof >/dev/null 2>&1; then
  echo -e "${YELLOW}Processes with most open files/sockets (top 20):${RESET}"
  lsof -nP | awk '{print $1,$2}' | tail -n +2 | awk '{cnt[$0]++} END{ for(i in cnt) print cnt[i], i }' | sort -rn | head -n 20
  # Better: list top procs by number of fds
  echo -e "${YELLOW}Top processes by open file descriptors:${RESET}"
  lsof -nP -F p | awk -F'p' '/^p/ {pid=$0} {print pid}' >/dev/null 2>&1
  # fallback simpler:
  lsof -nP | awk '{print $2}' | tail -n +2 | sort | uniq -c | sort -rn | head -n 20 | awk '{printf "%-8s PID %s\n", $1, $2}'
else
  echo -e "${YELLOW}lsof not installed.${RESET} (apt install lsof) -- skipping FD checks"
fi
echo

# Network: established connections count per remote IP (ss)
if command -v ss >/dev/null 2>&1; then
  echo -e "${YELLOW}Top remote IPs by established connections (tcp):${RESET}"
  ss -tan state established | awk '{print $5}' | awk -F: '{print $1}' | grep -v '^$' | sort | uniq -c | sort -rn | head -n 20
  echo

  # Consider IPs with many connections > threshold (suspicious)
  THRESHOLD=100
  echo -e "${YELLOW}Potential DDoS suspects (connections > ${THRESHOLD}):${RESET}"
  ss -tan state established | awk '{print $5}' | awk -F: '{print $1}' | grep -v '^$' | sort | uniq -c | awk -v t="$THRESHOLD" '$1>t{print $1" "$2}' | sort -rn | head -n 50 || echo "None"
  echo
else
  echo -e "${YELLOW}ss not available.${RESET} (should be on modern Linux)."
fi

# Network: show listening ports
echo -e "${YELLOW}Listening TCP ports:${RESET}"
if command -v ss >/dev/null 2>&1; then
  ss -tln | sed -n '1,200p'
else
  netstat -tln 2>/dev/null | sed -n '1,200p' || echo "no netstat/ss"
fi
echo

# Active connections by process (requires ss + pid info)
if command -v ss >/dev/null 2>&1; then
  echo -e "${YELLOW}Top processes by connection count (requires root):${RESET}"
  ss -tanp 2>/dev/null | awk -F'"' '/pid=/ {print $2}' | awk -F',' '{print $1}' | sort | uniq -c | sort -rn | head -n 20 || echo "Need root to list process names"
else
  echo -e "${YELLOW}Skipping per-process connections (ss missing)${RESET}"
fi
echo

# Show recent dropped packets (if iptables/nft counters available) <-- best-effort
if command -v iptables >/dev/null 2>&1; then
  echo -e "${YELLOW}iptables -L -v (first few rules):${RESET}"
  iptables -L -v -n | sed -n '1,20p' || true
else
  echo -e "${YELLOW}No iptables binary found (or requires privileges).${RESET}"
fi
echo

# Show suspicious processes: CPU>50% or MEM>50% (customizable)
echo -e "${YELLOW}Suspicious high-resource processes (CPU>20% or MEM>30%):${RESET}"
ps -eo pid,user,pcpu,pmem,cmd --sort=-pcpu | awk '$3>20 || $4>30 { printf "%6s %-10s %5.1f%% CPU %5.1f%% MEM %s\n", $1,$2,$3,$4,$5 }' | head -n 50 || echo "None"
echo

# Optional: list top N members of a specific group? (requires ID)
# Tools note
echo -e "${CYAN}============= NOTES =============${RESET}"
echo -e "• Untuk info lebih lengkap per-proses (I/O) install iotop: apt install iotop"
echo -e "• Untuk FD/per-socket detail install lsof: apt install lsof"
echo -e "• Jalankan dengan root (sudo) untuk melihat semua proses & pemilik"
echo -e "${CYAN}==================================${RESET}"
