#!/bin/bash

# ==============================
# CONFIG CLOUDLARE
# ==============================
ZONE_ID="5f405908bbcf1b3b20173307ce046584"
API_TOKEN="8_EQmOFSrPzb6wFtPFgrMTdLWDXzuuoDmUw2asJR"
DOMAIN="rexzystr.my.id"
# ==============================

CF_API="https://api.cloudflare.com/client/v4"

############################################
# VALIDASI DEPENDENCY
############################################

if ! command -v curl &> /dev/null; then
    echo "curl belum terinstall"
    exit 1
fi

if ! command -v jq &> /dev/null; then
    echo "jq belum terinstall, install dulu: apt install jq -y"
    exit 1
fi

############################################
# CREATE SUBDOMAIN
############################################

create_subdomain() {
    read -p "Masukkan IP VPS: " IP
    read -p "Masukkan Nama Host: " HOST

    HOST=$(echo "$HOST" | tr -cd 'a-zA-Z0-9.-')
    IP=$(echo "$IP" | tr -cd '0-9.')

    if [[ -z "$HOST" || -z "$IP" ]]; then
        echo "❌ Host/IP tidak valid"
        return
    fi

    FULL_DOMAIN="${HOST}.${DOMAIN}"

    echo "🔄 Membuat ${FULL_DOMAIN} → ${IP}"

    RESPONSE=$(curl -s -X POST "${CF_API}/zones/${ZONE_ID}/dns_records" \
        -H "Authorization: Bearer ${API_TOKEN}" \
        -H "Content-Type: application/json" \
        --data "{
          \"type\":\"A\",
          \"name\":\"${FULL_DOMAIN}\",
          \"content\":\"${IP}\",
          \"ttl\":1,
          \"proxied\":false
        }")

    SUCCESS=$(echo "$RESPONSE" | jq -r '.success')

    if [[ "$SUCCESS" == "true" ]]; then
        echo "✅ SUBDOMAIN BERHASIL DIBUAT"
        echo "🌐 $FULL_DOMAIN"
        echo "📌 $IP"
    else
        echo "❌ GAGAL MEMBUAT SUBDOMAIN"
        echo "$RESPONSE" | jq
    fi
}

############################################
# CHECK SUBDOMAIN
############################################

check_subdomain() {
    read -p "Masukkan Subdomain: " DOMAIN_CHECK

    RESULT=$(dig +short "$DOMAIN_CHECK")

    if [[ -z "$RESULT" ]]; then
        echo "❌ Subdomain tidak ditemukan"
    else
        echo "✅ Valid → $RESULT"
    fi
}

############################################
# DELETE SUBDOMAIN
############################################

delete_subdomain() {
    read -p "Masukkan Subdomain yang ingin dihapus: " DOMAIN_DELETE

    RESPONSE=$(curl -s -X GET "${CF_API}/zones/${ZONE_ID}/dns_records?name=${DOMAIN_DELETE}" \
        -H "Authorization: Bearer ${API_TOKEN}" \
        -H "Content-Type: application/json")

    RECORD_ID=$(echo "$RESPONSE" | jq -r '.result[0].id')

    if [[ "$RECORD_ID" == "null" || -z "$RECORD_ID" ]]; then
        echo "❌ Record tidak ditemukan"
        return
    fi

    DELETE_RESPONSE=$(curl -s -X DELETE "${CF_API}/zones/${ZONE_ID}/dns_records/${RECORD_ID}" \
        -H "Authorization: Bearer ${API_TOKEN}" \
        -H "Content-Type: application/json")

    SUCCESS=$(echo "$DELETE_RESPONSE" | jq -r '.success')

    if [[ "$SUCCESS" == "true" ]]; then
        echo "✅ Subdomain berhasil dihapus"
    else
        echo "❌ Gagal menghapus"
        echo "$DELETE_RESPONSE" | jq
    fi
}

############################################
# LIST SUBDOMAIN (FIXED)
############################################

list_subdomain() {
    echo "📋 Mengambil daftar subdomain..."

    RESPONSE=$(curl -s -X GET "${CF_API}/zones/${ZONE_ID}/dns_records?type=A&per_page=100" \
        -H "Authorization: Bearer ${API_TOKEN}" \
        -H "Content-Type: application/json")

    COUNT=$(echo "$RESPONSE" | jq '.result | length')

    if [[ "$COUNT" -eq 0 ]]; then
        echo "Tidak ada subdomain."
        return
    fi

    echo ""
    echo "$RESPONSE" | jq -r '.result[] | "🌐 \(.name) → \(.content)"'
}

############################################
# MENU
############################################

show_menu() {
    clear
    echo "================================="
    echo "        SUBDOMAIN MENU           "
    echo "================================="
    echo "1. Create Subdomain"
    echo "2. Cek Subdomain"
    echo "3. Delete Subdomain"
    echo "4. List Semua Subdomain"
    echo "0. Exit"
    echo "================================="
    read -p "Pilih Menu: " CHOICE

    case $CHOICE in
        1) create_subdomain ;;
        2) check_subdomain ;;
        3) delete_subdomain ;;
        4) list_subdomain ;;
        0) exit 0 ;;
        *) echo "❌ Pilihan tidak valid" ;;
    esac

    echo ""
    read -p "Tekan Enter untuk kembali..."
    show_menu
}

show_menu
