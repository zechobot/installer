#!/bin/bash
echo "Masukkan nama location (contoh: SGP): "
read location_name
echo "Masukkan id location (contoh: 1): "
read locid
echo "Masukkan nama node (contoh: Nodes): "
read node_name
echo "Masukkan deskripsi (contoh: Installer By Zechoxyz): "
read description
echo "Masukkan domain node (contoh: nodepanel.example.com): "
read domain
echo "Masukkan RAM (dalam MB): "
read ram
echo "Masukkan jumlah maksimum disk space (dalam MB): "
read disk_space

cd /var/www/pterodactyl || { echo "Direktori tidak ditemukan"; exit 1; }

echo "Membuat Location..."
php artisan p:location:make <<EOF
$location_name
$description
EOF

echo "Membuat Node..."
php artisan p:node:make <<EOF
$node_name
$description
$locid
https
$domain
yes
no
no
$ram
$ram
$disk_space
$disk_space
100
8080
2022
/var/lib/pterodactyl/volumes
EOF

echo " "
echo "Mengambil konfigurasi otomatis untuk Wings..."
export DB_HOST=$(grep "DB_HOST" .env | cut -d "=" -f2)
export DB_DATABASE=$(grep "DB_DATABASE" .env | cut -d "=" -f2)
export DB_USERNAME=$(grep "DB_USERNAME" .env | cut -d "=" -f2)
export DB_PASSWORD=$(grep "DB_PASSWORD" .env | cut -d "=" -f2)
NODE_ID=$(mysql -u "$DB_USERNAME" -p"$DB_PASSWORD" -h "$DB_HOST" -D "$DB_DATABASE" -N -e "SELECT id FROM nodes ORDER BY id DESC LIMIT 1;")
if [ -z "$NODE_ID" ]; then
    echo "❌ Gagal mendapatkan Node ID dari database."
    echo "⚠️  Silakan konfigurasi Wings secara manual."
else
    echo "✅ Node ID terdeteksi: $NODE_ID"
    echo "Membuat file konfigurasi..."
    mkdir -p /etc/pterodactyl
    php artisan p:node:configuration "$NODE_ID" > /etc/pterodactyl/config.yml

    echo "Menyalakan Wings..."
    systemctl daemon-reload
    systemctl enable wings
    systemctl restart wings
    sleep 2
    if systemctl is-active --quiet wings; then
        echo " "
        echo -e "\e[1;32m[SUKSES] Wings berhasil dikonfigurasi dan AKTIF (Online)!\e[0m"
    else
        echo " "
        echo -e "\e[1;31m[WARNING] Wings gagal start otomatis. Cek 'systemctl status wings' untuk detail.\e[0m"
    fi
fi

echo " "
echo "Proses pembuatan location dan node telah selesai."
