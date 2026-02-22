#!/bin/bash

# ==============================
# CONFIG (ISI SENDIRI)
# ==============================
ZONE_ID="5f405908bbcf1b3b20173307ce046584"
API_TOKEN="8_EQmOFSrPzb6wFtPFgrMTdLWDXzuuoDmUw2asJR"
DOMAIN="rexzystr.my.id"
# ==============================

CF_API="https://api.cloudflare.com/client/v4"

create_subdomain() {
    read -p "Masukkan IP VPS: " IP
    read -p "Masukkan Nama Host (contoh: bot1): " HOST

    HOST=$(echo "$HOST" | tr -cd 'a-zA-Z0-9.-')
    IP=$(echo "$IP" | tr -cd '0-9.')

    if [[ -z "$HOST" || -z "$IP" ]]; then
        echo "❌ Host/IP tidak valid"
        return
    fi

    FULL_DOMAIN="${HOST}.${DOMAIN}"

    echo ""
    echo "🔄 Membuat Subdomain..."
    echo "🌐 ${FULL_DOMAIN} → ${IP}"
    echo ""

    RESPONSE=$(curl -s -X POST "${CF_API}/zones/${ZONE_ID}/dns_records" \
        -H "Authorization: Bearer ${API_TOKEN}" \
        -H "Content-Type: application/json" \
        --data "{
            \"type\": \"A\",
            \"name\": \"${FULL_DOMAIN}\",
            \"content\": \"${IP}\",
            \"ttl\": 1,
            \"proxied\": false
        }")

    if echo "$RESPONSE" | grep -q '"success":true'; then
        echo "✅ BERHASIL MEMBUAT SUBDOMAIN"
        echo "🌐 ${FULL_DOMAIN}"
        echo "📌 ${IP}"
    else
        echo "❌ GAGAL MEMBUAT SUBDOMAIN"
        echo "$RESPONSE"
    fi
}

check_subdomain() {
    read -p "Masukkan Subdomain (contoh: bot1.${DOMAIN}): " DOMAIN_CHECK

    echo ""
    echo "🔍 Mengecek ${DOMAIN_CHECK}..."
    RESULT=$(dig +short "$DOMAIN_CHECK")

    if [[ -z "$RESULT" ]]; then
        echo "❌ SUBDOMAIN TIDAK DITEMUKAN"
    else
        echo "✅ SUBDOMAIN VALID"
        echo "📌 IP: ${RESULT}"
    fi
}

delete_subdomain() {
    read -p "Masukkan Subdomain yang ingin dihapus: " DOMAIN_DELETE

    if [[ -z "$DOMAIN_DELETE" ]]; then
        echo "❌ Domain tidak boleh kosong"
        return
    fi

    echo ""
    echo "🔎 Mencari DNS Record..."

    RECORD_ID=$(curl -s -X GET "${CF_API}/zones/${ZONE_ID}/dns_records?name=${DOMAIN_DELETE}" \
        -H "Authorization: Bearer ${API_TOKEN}" \
        -H "Content-Type: application/json" | grep -o '"id":"[^"]*' | head -n1 | cut -d':' -f2 | tr -d '"')

    if [[ -z "$RECORD_ID" ]]; then
        echo "❌ Record tidak ditemukan"
        return
    fi

    echo "🗑 Menghapus ${DOMAIN_DELETE}..."

    DELETE_RESPONSE=$(curl -s -X DELETE "${CF_API}/zones/${ZONE_ID}/dns_records/${RECORD_ID}" \
        -H "Authorization: Bearer ${API_TOKEN}" \
        -H "Content-Type: application/json")

    if echo "$DELETE_RESPONSE" | grep -q '"success":true'; then
        echo "✅ BERHASIL MENGHAPUS SUBDOMAIN"
    else
        echo "❌ GAGAL MENGHAPUS SUBDOMAIN"
        echo "$DELETE_RESPONSE"
    fi
}

show_menu() {
    clear
    echo "================================="
    echo "        SUBDOMAIN MENU           "
    echo "================================="
    echo "1. Create Subdomain"
    echo "2. Cek Subdomain"
    echo "3. Delete Subdomain"
    echo "0. Exit"
    echo "================================="
    read -p "Pilih Menu (angka): " CHOICE

    case $CHOICE in
        1) create_subdomain ;;
        2) check_subdomain ;;
        3) delete_subdomain ;;
        0) echo "Keluar..."; exit 0 ;;
        *) echo "❌ Pilihan tidak valid" ;;
    esac

    echo ""
    read -p "Tekan Enter untuk kembali ke menu..."
    show_menu
}

show_menu
