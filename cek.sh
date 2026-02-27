#!/bin/bash

IP=$(curl -s ifconfig.me)

OS=$(grep PRETTY_NAME /etc/os-release | cut -d= -f2 | tr -d '"')

CPU_CORE=$(nproc)

CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print 100-$8"%"}')

RAM_TOTAL=$(free -h | awk '/Mem:/ {print $2}')
RAM_USED=$(free -h | awk '/Mem:/ {print $3}')
RAM_PERCENT=$(free | awk '/Mem:/ {printf("%.0f%%"), $3/$2*100}')

DISK=$(df -h / | awk 'NR==2 {print $2}')

UPTIME=$(uptime -p)

PANEL="Not Installed"
DOMAIN="Not Detected"
SSL="Not Active"

if [ -d "/var/www/pterodactyl" ]; then
PANEL="Installed"

DOMAIN=$(grep APP_URL /var/www/pterodactyl/.env 2>/dev/null | cut -d= -f2)

if echo "$DOMAIN" | grep -q https; then
SSL="Active"
fi
fi

if systemctl is-active --quiet wings; then
WINGS="Active"
WINGS_VERSION=$(wings --version 2>/dev/null | head -n1)
else
WINGS="Not Active"
WINGS_VERSION="-"
fi

if systemctl is-active --quiet docker; then
DOCKER="Active"
else
DOCKER="Not Active"
fi

if systemctl is-active --quiet nginx; then
NGINX="Active"
else
NGINX="Not Active"
fi

echo "VPS ADVANCED INFORMATION"
echo ""
echo "IP: $IP"
echo ""
echo "OS: $OS"
echo "CPU Core: $CPU_CORE"
echo "CPU Usage: $CPU_USAGE"
echo "RAM Total: $RAM_TOTAL"
echo "RAM Used: $RAM_USED ($RAM_PERCENT)"
echo "Disk: $DISK"
echo "Uptime: $UPTIME"
echo "Panel: $PANEL"
echo "Panel Domain: $DOMAIN"
echo "Panel Version: Detected"
echo "SSL: $SSL"
echo "Wings: $WINGS"
echo "Wings Version: $WINGS_VERSION"
echo "Docker: $DOCKER"
echo "Nginx: $NGINX"
