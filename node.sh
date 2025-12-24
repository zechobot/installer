#!/bin/bash


# Minta input dari pengguna.
echo "Masukkan domain: "
read domain
# Ubah ke direktori pterodactyl
cd /var/www/pterodactyl || { echo "Direktori tidak ditemukan"; exit 1; }

# Membuat lokasi baru
php artisan p:location:make <<EOF
Singapore
SGP
EOF

# Membuat node baru
php artisan p:node:make <<EOF
Ubuntu
SGP
1
https
$domain
yes
no
no
9999999999999999999999999
0
9999999999999999999999999
0
100
8080
2022
/var/lib/pterodactyl/volumes
EOF

echo "Proses pembuatan lokasi dan node telah selesai."
