#!/bin/bash

# Colors for terminal output
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Display banner
echo -e "${GREEN}"
echo " _____      _            _ "
echo "|  _  |    | |          | |"
echo "| | | | ___| |_ __ _  __| |"
echo "| | | |/ __| __/ _\` |/ _\` |"
echo "\\ \\_/ /\\__ \\ || (_| | (_| |"
echo " \\___/ |___/\\__\\__,_|\\__,_|"
echo -e "${NC}"

# Function to validate IP address
validate_ip() {
    local ip=$1
    if [[ $ip =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        return 0
    else
        return 1
    fi
}

# Function to get IP from user
get_ip() {
    while true; do
        read -p "Enter the IPv4 address: " user_ip
        if validate_ip "$user_ip"; then
            echo "$user_ip"
            break
        else
            echo "Invalid IPv4 address. Please try again."
        fi
    done
}

# Main menu
echo "Please select an option:"
echo "1. Optimize server"
echo "2. Configure Iran server"
echo "3. Configure foreign server"
echo "4. Install Marzban Node"
echo "5. Install HAProxy"
echo "6. Install and test Speedtest"
echo "7. Edit HAProxy configuration"
echo "8. Restart HAProxy service"

read -p "Your choice: " choice

case $choice in
    1)
        # Optimize server
        echo "Optimizing server..."
        
        # Edit limits.conf
        echo "Editing /etc/security/limits.conf..."
        echo "* soft nofile 51200" | sudo tee /etc/security/limits.conf > /dev/null
        echo "* hard nofile 51200" | sudo tee -a /etc/security/limits.conf > /dev/null
        
        # Run ulimit command
        echo "Running ulimit..."
        ulimit -n 51200
        
        # Edit sysctl.conf
        echo "Editing /etc/ufw/sysctl.conf and /etc/sysctl.conf..."
        SYSCTL_SETTINGS="fs.file-max = 51200
net.core.rmem_max = 67108864
net.core.wmem_max = 67108864
net.core.netdev_max_backlog = 250000
net.core.somaxconn = 4096
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_tw_recycle = 0
net.ipv4.tcp_fin_timeout = 30
net.ipv4.tcp_keepalive_time = 1200
net.ipv4.ip_local_port_range = 10000 65000
net.ipv4.tcp_max_syn_backlog = 8192
net.ipv4.tcp_max_tw_buckets = 5000
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_mem = 25600 51200 102400
net.ipv4.tcp_rmem = 4096 87380 67108864
net.ipv4.tcp_wmem = 4096 65536 67108864
net.ipv4.tcp_mtu_probing = 1
net.ipv4.tcp_congestion_control = hybla"
        
        echo "$SYSCTL_SETTINGS" | sudo tee /etc/ufw/sysctl.conf > /dev/null
        echo "$SYSCTL_SETTINGS" | sudo tee -a /etc/sysctl.conf > /dev/null
        
        # Configure firewall
        read -p "Enter SSH port: " sshPort
        sudo ufw default deny incoming
        sudo ufw default allow outgoing
        sudo ufw limit "$sshPort"
        
        read -p "Enter additional ports (space-separated): " ports
        sudo ufw allow $ports
        
        # Enable and reload firewall
        echo "Enabling and reloading UFW firewall..."
        sudo ufw --force enable
        sudo ufw reload
        
        # Add cron job to reload firewall every 30 minutes
        (crontab -l 2>/dev/null; echo "*/30 * * * * /usr/sbin/ufw reload") | crontab -
        
        echo "Server optimization completed successfully."
        ;;
    2)
        # Configure Iran server
        echo "Configuring Iran server..."
        
        # Get IP from user
        echo "Please enter the foreign server's IPv4 address:"
        FOREIGN_IP=$(get_ip)
        
        # Create the localv6.sh script
        cat <<EOF | sudo tee /root/localv6.sh > /dev/null
#!/bin/bash

ip tunnel add 6to4_To_KH mode sit remote $FOREIGN_IP local 0.0.0.0
ip -6 addr add fdba:53d2:dffe::1/64 dev 6to4_To_KH
ip link set 6to4_To_KH mtu 1480
ip link set 6to4_To_KH up

ip -6 tunnel add GRE6Tun_To_KH mode ip6gre remote fdba:53d2:dffe::2 local fdba:53d2:dffe::1
ip addr add 172.21.1.1/30 dev GRE6Tun_To_KH
ip addr add 192.168.32.1/24 dev GRE6Tun_To_KH
ip link set GRE6Tun_To_KH mtu 1436
ip link set GRE6Tun_To_KH up

/sbin/modprobe ipip
ip -6 tunnel add IP6IP6_To_KH2 mode ip6ip6 remote fdba:53d2:dffe::2 local fdba:53d2:dffe::1 ttl 255
ip -6 addr add 2002:0db8:1234:a232::1/64 dev IP6IP6_To_KH2
ip link set IP6IP6_To_KH2 up
ip -6 route add 2002::/16 dev IP6IP6_To_KH2
ip -6 addr add 2002:0db8:1234:a032::1/64 dev IP6IP6_To_KH2
ip link set IP6IP6_To_KH2 mtu 1436
EOF
        
        sudo chmod +x /root/localv6.sh
        
        # Add to cron job
        (crontab -l 2>/dev/null; echo "@reboot /bin/bash /root/localv6.sh") | crontab -
        
        echo "Iran server configuration completed successfully."
        ;;
    3)
        # Configure foreign server
        echo "Configuring foreign server..."
        
        # Get IP from user
        echo "Please enter the Iran server's IPv4 address:"
        IRAN_IP=$(get_ip)
        
        # Create the localv6.sh script
        cat <<EOF | sudo tee /root/localv6.sh > /dev/null
#!/bin/bash

ip tunnel add 6to4_To_IR mode sit remote $IRAN_IP local 0.0.0.0
ip -6 addr add fdba:53d2:dffe::2/64 dev 6to4_To_IR
ip link set 6to4_To_IR mtu 1480
ip link set 6to4_To_IR up
ip -6 tunnel add GRE6Tun_To_IR mode ip6gre remote fdba:53d2:dffe::1 local fdba:53d2:dffe::2
ip addr add 172.21.1.2/30 dev GRE6Tun_To_IR
ip addr add 192.168.32.2/24 dev GRE6Tun_To_IR
ip link set GRE6Tun_To_IR mtu 1436
ip link set GRE6Tun_To_IR up

/sbin/modprobe ipip
ip -6 tunnel add IP6IP6_To_IR mode ip6ip6 remote fdba:53d2:dffe::1 local fdba:53d2:dffe::2 ttl 255
ip -6 addr add 2002:0db8:1234:a232::2/64 dev IP6IP6_To_IR
ip link set IP6IP6_To_IR up
ip -6 route add 2002::/16 dev IP6IP6_To_IR
ip -6 addr add 2002:0db8:1234:a032::2/64 dev IP6IP6_To_IR
ip link set IP6IP6_To_IR mtu 1436
EOF
        
        sudo chmod +x /root/localv6.sh
        
        # Add to cron job
        (crontab -l 2>/dev/null; echo "@reboot /bin/bash /root/localv6.sh") | crontab -
        
        echo "Foreign server configuration completed successfully."
        ;;
    4)
        # Install Marzban Node
        echo "Installing Marzban Node..."
        sudo bash -c "$(curl -sL https://github.com/Gozargah/Marzban-scripts/raw/master/marzban-node.sh)" @ install
        ;;
    5)
        # Install HAProxy
        echo "Installing HAProxy..."
        bash <(curl -Ls --ipv4 https://github.com/Musixal/haproxy/raw/main/haproxy.sh)
        ;;
    6)
        # Install and test Speedtest
        echo "Installing and testing Speedtest..."
        cd /root && mkdir -p speedtest && cd speedtest && wget https://install.speedtest.net/app/cli/ookla-speedtest-1.2.0-linux-x86_64.tgz && tar -xvzf ookla-speedtest* && cp speedtest /usr/bin/
        ;;
    7)
        # Edit HAProxy configuration
        echo "Opening HAProxy configuration file in nano..."
        sudo nano /etc/haproxy/haproxy.cfg
        echo "HAProxy configuration file edited successfully."
        ;;
    8)
        # Restart HAProxy service
        echo "Restarting HAProxy service..."
        sudo systemctl restart haproxy
        echo "HAProxy service restarted successfully."
        ;;
    *)
        echo "Invalid choice."
        ;;
esac
