#!/bin/bash

# Sakura theme colors
SAKURA_PINK='\033[38;5;218m'
SOFT_PINK='\033[38;5;217m'
CHERRY_BLOSSOM='\033[38;5;225m'
DEEP_PINK='\033[38;5;205m'
ROSE_GOLD='\033[38;5;216m'
PEARL_WHITE='\033[38;5;255m'
LAVENDER='\033[38;5;183m'
MINT_GREEN='\033[38;5;158m'
CORAL='\033[38;5;209m'
BLUSH='\033[38;5;224m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

RED="$CORAL"
GREEN="$MINT_GREEN"
YELLOW="$ROSE_GOLD"
BLUE="$LAVENDER"
PURPLE="$DEEP_PINK"
CYAN="$SAKURA_PINK"
WHITE="$PEARL_WHITE"

print_section() {
    echo -e "${BOLD}${SAKURA_PINK}🌸 $1${NC}"
}

print_info() {
    local label="$1" value="$2" color="${3:-$SOFT_PINK}"
    printf "  ${CHERRY_BLOSSOM}%-12s${NC} ${color}%s${NC}\n" "$label:" "$value"
}

print_dual_info() {
    local label1="$1" value1="$2" label2="$3" value2="$4" color1="${5:-$SOFT_PINK}" color2="${6:-$SOFT_PINK}"
    printf "  ${CHERRY_BLOSSOM}%-12s${NC} ${color1}%-25s${NC} ${CHERRY_BLOSSOM}%-12s${NC} ${color2}%s${NC}\n" "$label1:" "$value1" "$label2:" "$value2"
}

create_progress_bar() {
    local percentage=$1 width=20 filled=$((percentage * width / 100)) empty=$((width - filled)) bar=""

    for ((i=0; i<filled; i++)); do bar+="█"; done
    for ((i=0; i<empty; i++)); do bar+="░"; done

    if [ "$percentage" -gt 80 ]; then
        echo -e "${CORAL}${bar}${NC} ${percentage}%"
    elif [ "$percentage" -gt 60 ]; then
        echo -e "${ROSE_GOLD}${bar}${NC} ${percentage}%"
    else
        echo -e "${MINT_GREEN}${bar}${NC} ${percentage}%"
    fi
}

bytes_to_human() {
    local bytes=$1
    if [ "$bytes" -ge 1073741824 ]; then
        echo "$(echo "scale=2; $bytes/1073741824" | bc)GB"
    elif [ "$bytes" -ge 1048576 ]; then
        echo "$(echo "scale=2; $bytes/1048576" | bc)MB"
    elif [ "$bytes" -ge 1024 ]; then
        echo "$(echo "scale=2; $bytes/1024" | bc)KB"
    else
        echo "${bytes}B"
    fi
}

clear

# System info
hostname=$(hostname)
os_name=$(lsb_release -d 2>/dev/null | cut -f2 | sed 's/^[[:space:]]*//' || cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)
kernel_version=$(uname -r)
architecture=$(uname -m)
uptime_info=$(uptime -p 2>/dev/null || uptime | sed 's/.*up \([^,]*\).*/\1/')
current_user=$(whoami)

# CPU info
cpu_model=$(grep "model name" /proc/cpuinfo | head -1 | cut -d':' -f2 | sed 's/^[[:space:]]*//')
cpu_physical_cores=$(grep "cpu cores" /proc/cpuinfo | head -1 | cut -d':' -f2 | sed 's/^[[:space:]]*//' || echo "N/A")
cpu_logical_processors=$(nproc)
cpu_sockets=$(grep "physical id" /proc/cpuinfo | sort -u | wc -l)
cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)

if [ "$cpu_physical_cores" != "N/A" ] && [ "$cpu_sockets" -gt 0 ]; then
    total_physical_cores=$((cpu_physical_cores * cpu_sockets))
else
    total_physical_cores=$(lscpu | grep "Core(s) per socket" | awk '{print $4}' 2>/dev/null || echo "$cpu_logical_processors")
    if [ "$cpu_sockets" -gt 0 ]; then
        total_physical_cores=$((total_physical_cores * cpu_sockets))
    fi
fi

# Memory info
mem_info=$(free -b)
total_mem=$(echo "$mem_info" | awk 'NR==2{print $2}')
used_mem=$(echo "$mem_info" | awk 'NR==2{print $3}')
mem_usage_percent=$(echo "scale=0; $used_mem*100/$total_mem" | bc)

# Disk info
disk_info=$(df -h / | tail -1)
total_disk=$(echo "$disk_info" | awk '{print $2}')
used_disk=$(echo "$disk_info" | awk '{print $3}')
disk_usage_percent=$(echo "$disk_info" | awk '{print $5}' | sed 's/%//')

# Network info
primary_ip=$(hostname -I | awk '{print $1}' 2>/dev/null || ip route get 1.1.1.1 | grep -oP 'src \K\S+' 2>/dev/null || echo "N/A")
public_ipv6=$(ip -6 addr show | grep 'inet6.*global' | head -1 | awk '{print $2}' | cut -d'/' -f1 2>/dev/null || echo "N/A")

if [[ "$primary_ip" =~ ^10\. ]] || [[ "$primary_ip" =~ ^192\.168\. ]] || [[ "$primary_ip" =~ ^172\.(1[6-9]|2[0-9]|3[0-1])\. ]]; then
    private_ip="$primary_ip"
    public_ipv4=$(curl -s ifconfig.me 2>/dev/null || curl -s ipinfo.io/ip 2>/dev/null || echo "N/A")
else
    private_ip="N/A"
    public_ipv4="$primary_ip"
fi

# Load & time
load_avg=$(uptime | grep -o 'load average:.*' | cut -d':' -f2 | sed 's/^[[:space:]]*//')
load_1min=$(echo "$load_avg" | cut -d',' -f1 | sed 's/^[[:space:]]*//')
local_time=$(date '+%Y-%m-%d %H:%M:%S')
timezone=$(timedatectl show --property=Timezone --value 2>/dev/null || date +%Z)
shell_name=$(basename "$SHELL")

# Virtualization
virt_type="Bare Metal"
if [ -f /proc/cpuinfo ] && grep -q "hypervisor" /proc/cpuinfo; then
    virt_type="Virtual Machine"
elif [ -f /.dockerenv ]; then
    virt_type="Docker Container"
elif grep -q "container=lxc" /proc/1/environ 2>/dev/null; then
    virt_type="LXC Container"
elif systemd-detect-virt >/dev/null 2>&1; then
    virt_type="$(systemd-detect-virt)"
fi

# Package updates
security_updates=0
regular_updates=0
if command -v apt >/dev/null 2>&1; then
    apt_output=$(apt list --upgradable 2>/dev/null | grep -v "WARNING")
    if [ -n "$apt_output" ]; then
        regular_updates=$(echo "$apt_output" | wc -l)
        regular_updates=$((regular_updates - 1))
    fi
    if command -v unattended-upgrade >/dev/null 2>&1; then
        security_updates=$(apt list --upgradable 2>/dev/null | grep -i security | wc -l)
    fi
elif command -v yum >/dev/null 2>&1; then
    regular_updates=$(yum check-update --quiet 2>/dev/null | wc -l)
    security_updates=$(yum --security check-update --quiet 2>/dev/null | wc -l)
elif command -v dnf >/dev/null 2>&1; then
    regular_updates=$(dnf check-update --quiet 2>/dev/null | wc -l)
    security_updates=$(dnf --security check-update --quiet 2>/dev/null | wc -l)
fi

# Security & user info
last_login=$(last -n 1 "$current_user" | head -1 | awk '{print $3, $4, $5, $6}' 2>/dev/null || echo "N/A")
failed_logins=$(grep "Failed password" /var/log/auth.log 2>/dev/null | tail -10 | wc -l || echo "0")

services_to_check=("ssh" "sshd" "nginx" "apache2" "mysql" "postgresql" "docker" "fail2ban")
critical_services_down=()
for service in "${services_to_check[@]}"; do
    if systemctl is-enabled "$service" >/dev/null 2>&1; then
        if ! systemctl is-active "$service" >/dev/null 2>&1; then
            critical_services_down+=("$service")
        fi
    fi
done

# Greeting & users
current_hour=$(date +%H)
if [ "$current_hour" -lt 12 ]; then
    greeting="Good morning"
elif [ "$current_hour" -lt 17 ]; then
    greeting="Good afternoon"
else
    greeting="Good evening"
fi

other_users=$(who | grep -v "^${current_user} " | wc -l)
if [ "$other_users" -gt 0 ]; then
    users_info="${other_users} other users online"
else
    users_info="You are the only user online"
fi

# Reboot info
last_reboot_time=$(who -b 2>/dev/null | awk '{print $3, $4}' || uptime -s 2>/dev/null || echo "Unknown")
reboot_reason="Unknown"
if [ -f /var/log/wtmp ]; then
    if last -x shutdown 2>/dev/null | head -1 | grep -q "shutdown"; then
        reboot_reason="Planned"
    else
        reboot_reason="Unplanned"
    fi
fi

# Swap info
swap_info=$(free -b | grep "Swap:")
if [ -n "$swap_info" ]; then
    total_swap=$(echo "$swap_info" | awk '{print $2}')
    used_swap=$(echo "$swap_info" | awk '{print $3}')
    if [ "$total_swap" -gt 0 ]; then
        swap_usage_percent=$(echo "scale=0; $used_swap*100/$total_swap" | bc)
    else
        swap_usage_percent=0
        total_swap=0
        used_swap=0
    fi
else
    swap_usage_percent=0
    total_swap=0
    used_swap=0
fi

echo ""

# Header
content="KASTATS System Information ${hostname}"
box_width=77
content_length=${#content}
padding=$(( (box_width - content_length) / 2 ))
remaining_padding=$(( box_width - content_length - padding ))

padded_content=""
for ((i=0; i<padding; i++)); do padded_content+=" "; done
padded_content+="${BOLD}${PEARL_WHITE}KASTATS${NC} ${CHERRY_BLOSSOM}System Information${NC} ${BOLD}${SAKURA_PINK}${hostname}${NC}"
for ((i=0; i<remaining_padding; i++)); do padded_content+=" "; done

echo -e "${BOLD}${DEEP_PINK}┌─────────────────────────────────────────────────────────────────────────────┐${NC}"
echo -e "${BOLD}${DEEP_PINK}│${NC}${padded_content}${BOLD}${DEEP_PINK}│${NC}"
echo -e "${BOLD}${DEEP_PINK}└─────────────────────────────────────────────────────────────────────────────┘${NC}"
echo ""
echo -e "${BOLD}${PEARL_WHITE}${greeting} ${SAKURA_PINK}${current_user}${NC}${BOLD}${PEARL_WHITE}! Welcome to ${SAKURA_PINK}${hostname} 🌸${NC}"
echo -e "${CHERRY_BLOSSOM}${users_info}${NC}"
echo ""

print_section "SYSTEM"
print_dual_info "OS" "$os_name" "Kernel" "$kernel_version"
print_dual_info "Host" "$hostname" "Uptime" "$uptime_info"
print_dual_info "Platform" "$virt_type" "Arch" "$architecture"
print_dual_info "Shell" "$shell_name" "Time" "$timezone ($local_time)"
print_dual_info "Last Boot" "$last_reboot_time" "Reboot" "$reboot_reason"
echo ""

print_section "HARDWARE"
print_info "CPU" "$cpu_model"
printf "  ${CHERRY_BLOSSOM}%-12s${NC} ${SOFT_PINK}%-38s${NC} %s\n" "Cores:" "${total_physical_cores}C/${cpu_logical_processors}T" "$(create_progress_bar ${cpu_usage%.*})"
printf "  ${CHERRY_BLOSSOM}%-12s${NC} ${SOFT_PINK}%-38s${NC} %s\n" "Memory:" "$(bytes_to_human $used_mem) / $(bytes_to_human $total_mem)" "$(create_progress_bar $mem_usage_percent)"
if [ "$total_swap" -gt 0 ]; then
    printf "  ${CHERRY_BLOSSOM}%-12s${NC} ${SOFT_PINK}%-38s${NC} %s\n" "Swap:" "$(bytes_to_human $used_swap) / $(bytes_to_human $total_swap)" "$(create_progress_bar $swap_usage_percent)"
fi
printf "  ${CHERRY_BLOSSOM}%-12s${NC} ${SOFT_PINK}%-38s${NC} %s\n" "Disk (/):" "${used_disk} / ${total_disk}" "$(create_progress_bar $disk_usage_percent)"
echo ""

print_section "NETWORK"
if [ "$private_ip" != "N/A" ]; then
    print_dual_info "Private IP" "$private_ip" "Public IPv4" "$public_ipv4"
    if [ "$public_ipv6" != "N/A" ]; then
        print_info "Public IPv6" "$public_ipv6"
    fi
else
    print_dual_info "Public IPv4" "$public_ipv4" "Public IPv6" "$public_ipv6"
fi
echo ""

print_section "SECURITY & UPDATES"
if [ "$regular_updates" -gt 0 ] || [ "$security_updates" -gt 0 ]; then
    if [ "$security_updates" -gt 0 ]; then
        print_dual_info "Security" "${security_updates} updates" "Regular" "${regular_updates} updates" "${CORAL}" "${ROSE_GOLD}"
        echo -e "  ${ROSE_GOLD}🌸 Security updates available! Run: ${PEARL_WHITE}sudo apt update && sudo apt upgrade${NC}"
    else
        print_dual_info "Security" "Up to date" "Regular" "${regular_updates} updates" "${MINT_GREEN}" "${ROSE_GOLD}"
    fi
else
    print_info "Updates" "System is up to date" "${MINT_GREEN}"
fi

if [ "$last_login" != "N/A" ]; then
    print_info "Last Login" "$last_login"
fi

if [ "$failed_logins" -gt 0 ]; then
    print_info "Failed Logins" "${failed_logins} recent attempts" "${ROSE_GOLD}"
fi
echo ""

print_section "SYSTEM STATUS"
load_1min_int=${load_1min%.*}
if [ "$load_1min_int" -gt "$cpu_logical_processors" ]; then
    load_interpretation="High Load"
    load_color="$CORAL"
elif [ "$load_1min_int" -gt $((cpu_logical_processors * 75 / 100)) ]; then
    load_interpretation="Moderate Load"
    load_color="$ROSE_GOLD"
else
    load_interpretation="Normal Load"
    load_color="$MINT_GREEN"
fi

print_dual_info "Load Avg" "$load_avg" "Status" "$load_interpretation" "$SOFT_PINK" "$load_color"

if [ ${#critical_services_down[@]} -gt 0 ]; then
    services_down_str=$(IFS=', '; echo "${critical_services_down[*]}")
    print_info "Services Down" "$services_down_str" "${CORAL}"
else
    print_info "Services" "All critical services running" "${MINT_GREEN}"
fi

if [ "$disk_usage_percent" -gt 90 ]; then
    echo -e "  ${CORAL}🌸 CRITICAL: Disk usage is ${disk_usage_percent}% - Immediate action required!${NC}"
elif [ "$disk_usage_percent" -gt 80 ]; then
    echo -e "  ${ROSE_GOLD}🌸 WARNING: Disk usage is ${disk_usage_percent}% - Consider cleanup${NC}"
fi

echo ""