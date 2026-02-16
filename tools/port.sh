#!/bin/bash

# Clear terminal biar rapi
clear
echo "===================================================="
echo "   PTERODACTYL AUTO GENERATE ALLOCATION (API)      "
echo "===================================================="
echo ""

# Input data secara manual
read -p "Masukkan Domain Panel: " PANEL_URL
read -p "Masukkan Apikey PLTA: " API_KEY
read -p "Masukkan Node id(default 1): " NODE_ID
read -p "Masukkan IP Address Node: " IP_ADDR
read -p "Masukkan IP Alias: " IP_ALIAS
read -p "Masukkan Port/Range Port (contoh: 1024-6000): " PORT_INPUT

echo ""
echo "----------------------------------------------------"
echo "Sedang memproses... Mohon tunggu."
echo "----------------------------------------------------"

# Eksekusi Curl
RESPONSE=$(curl -s -i -X POST "$PANEL_URL/api/application/nodes/$NODE_ID/allocations" \
  -H "Authorization: Bearer $API_KEY" \
  -H "Content-Type: application/json" \
  -H "Accept: Application/vnd.pterodactyl.v1+json" \
  -d "{
    \"ip\": \"$IP_ADDR\",
    \"alias\": \"$IP_ALIAS\",
    \"ports\": [\"$PORT_INPUT\"]
  }")

# Mengambil HTTP Status Code dari header
HTTP_STATUS=$(echo "$RESPONSE" | grep HTTP | tail -1 | awk '{print $2}')

echo ""
if [[ "$HTTP_STATUS" == "204" || "$HTTP_STATUS" == "200" || "$HTTP_STATUS" == "201" ]]; then
    echo "✅ BERHASIL!"
    echo "Port $PORT_INPUT telah ditambahkan ke Node $NODE_ID."
    echo "Silakan cek bagian Allocation di Panel Anda."
else
    echo "❌ GAGAL (Status Code: $HTTP_STATUS)"
    echo "Detail Error dari Panel:"
    echo "$RESPONSE" | sed -e '1,/^\s*$/d' # Menampilkan body JSON saja
fi

echo "----------------------------------------------------"
