#!/bin/bash

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
BOLD='\033[1m'
NC='\033[0m'

GITHUB_USER="KeaneAudric20"
REPO_NAME="kastats"
GITHUB_URL="https://raw.githubusercontent.com/${GITHUB_USER}/${REPO_NAME}/main"

INSTALL_DIR="/usr/local/bin"
PROFILE_DIR="/etc/profile.d"

print_header() {
    clear

    # Calculate proper centering
    local box_width=77
    local title1="KASTATS INSTALLER"
    local title2="System Information Display Tool"

    local title1_len=${#title1}
    local title2_len=${#title2}

    local padding1=$(( (box_width - title1_len) / 2 ))
    local remaining1=$(( box_width - title1_len - padding1 ))

    local padding2=$(( (box_width - title2_len) / 2 ))
    local remaining2=$(( box_width - title2_len - padding2 ))

    # Build padded content
    local padded1=""
    local padded2=""

    for ((i=0; i<padding1; i++)); do padded1+=" "; done
    padded1+="${BOLD}${WHITE}${title1}${NC}"
    for ((i=0; i<remaining1; i++)); do padded1+=" "; done

    for ((i=0; i<padding2; i++)); do padded2+=" "; done
    padded2+="${PURPLE}${title2}${NC}"
    for ((i=0; i<remaining2; i++)); do padded2+=" "; done

    echo -e "${BOLD}${CYAN}┌─────────────────────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${BOLD}${CYAN}│${NC}${padded1}${BOLD}${CYAN}│${NC}"
    echo -e "${BOLD}${CYAN}│${NC}${padded2}${BOLD}${CYAN}│${NC}"
    echo -e "${BOLD}${CYAN}└─────────────────────────────────────────────────────────────────────────────┘${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

check_requirements() {
    print_info "Checking system requirements..."

    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root or with sudo"
        echo "Please run: sudo bash setup.sh"
        exit 1
    fi

    local missing_commands=()
    for cmd in curl wget bc; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing_commands+=("$cmd")
        fi
    done

    if [ ${#missing_commands[@]} -gt 0 ]; then
        print_warning "Installing missing dependencies: ${missing_commands[*]}"

        if command -v apt >/dev/null 2>&1; then
            apt update >/dev/null 2>&1
            apt install -y "${missing_commands[@]}" >/dev/null 2>&1
        elif command -v yum >/dev/null 2>&1; then
            yum install -y "${missing_commands[@]}" >/dev/null 2>&1
        elif command -v dnf >/dev/null 2>&1; then
            dnf install -y "${missing_commands[@]}" >/dev/null 2>&1
        else
            print_error "Could not install dependencies. Please install manually: ${missing_commands[*]}"
            exit 1
        fi
    fi

    print_success "System requirements met"
}

show_theme_selection() {
    echo -e "${BOLD}${WHITE}Available Themes:${NC}"
    echo ""
    echo -e "${PURPLE}1)${NC} ${BOLD}Sakura Theme${NC} 🌸"
    echo -e "   ${PURPLE}•${NC} Beautiful pink cherry blossom colors"
    echo -e "   ${PURPLE}•${NC} Soft pastels with coral accents"
    echo ""
    echo -e "${CYAN}2)${NC} ${BOLD}Sky Blue Theme${NC} ☁️"
    echo -e "   ${CYAN}•${NC} Clean sky blue and cloud colors"
    echo -e "   ${CYAN}•${NC} Professional azure palette"
    echo ""
}

get_theme_choice() {
    while true; do
        show_theme_selection
        echo -n -e "${BOLD}${WHITE}Choose your theme (1 or 2): ${NC}"
        read -r theme_choice

        case $theme_choice in
            1)
                THEME="sakura"
                THEME_FILE="sakura_kastats.sh"
                THEME_NAME="Sakura Theme 🌸"
                break
                ;;
            2)
                THEME="blue"
                THEME_FILE="blue_kastats.sh"
                THEME_NAME="Sky Blue Theme ☁️"
                break
                ;;
            *)
                print_error "Invalid choice. Please enter 1 or 2."
                echo ""
                ;;
        esac
    done
}

get_ssh_login_choice() {
    echo ""
    echo -e "${BOLD}${WHITE}SSH Login Integration:${NC}"
    echo -e "${GREEN}•${NC} Show KASTATS automatically when users SSH into the server"
    echo -e "${GREEN}•${NC} Provides instant system overview for administrators"
    echo -e "${GREEN}•${NC} Can be easily disabled later if needed"
    echo ""

    while true; do
        echo -n -e "${BOLD}${WHITE}Enable SSH login integration? (y/n): ${NC}"
        read -r ssh_choice

        case $ssh_choice in
            [Yy]|[Yy][Ee][Ss])
                ENABLE_SSH_LOGIN=true
                break
                ;;
            [Nn]|[Nn][Oo])
                ENABLE_SSH_LOGIN=false
                break
                ;;
            *)
                print_error "Please enter 'y' for yes or 'n' for no."
                ;;
        esac
    done
}

download_and_install() {
    print_info "Downloading ${THEME_NAME}..."

    if ! curl -sSL "${GITHUB_URL}/${THEME_FILE}" -o "/tmp/kastats_temp.sh"; then
        print_error "Failed to download ${THEME_FILE}"
        exit 1
    fi

    if [ ! -s "/tmp/kastats_temp.sh" ]; then
        print_error "Downloaded file is empty or corrupted"
        exit 1
    fi

    # Check if kastats is already installed
    if [ -f "${INSTALL_DIR}/kastats" ]; then
        print_warning "Existing KASTATS installation found - replacing..."
        rm -f "${INSTALL_DIR}/kastats"
    fi

    print_info "Installing KASTATS to ${INSTALL_DIR}/kastats..."

    mkdir -p "$INSTALL_DIR"
    cp "/tmp/kastats_temp.sh" "${INSTALL_DIR}/kastats"
    chmod +x "${INSTALL_DIR}/kastats"
    rm -f "/tmp/kastats_temp.sh"

    print_success "KASTATS installed successfully"
}

setup_ssh_login() {
    if [ "$ENABLE_SSH_LOGIN" = true ]; then
        # Check if SSH integration already exists
        if [ -f "${PROFILE_DIR}/kastats.sh" ]; then
            print_warning "Existing SSH integration found - replacing..."
            rm -f "${PROFILE_DIR}/kastats.sh"
        fi

        print_info "Setting up SSH login integration..."

        cat > "${PROFILE_DIR}/kastats.sh" << 'EOF'
#!/bin/bash
if [[ $- == *i* ]] && [[ -n "$SSH_CONNECTION" || -n "$SSH_CLIENT" || -n "$SSH_TTY" ]]; then
    if command -v kastats >/dev/null 2>&1; then
        kastats
    fi
fi
EOF

        chmod +x "${PROFILE_DIR}/kastats.sh"
        print_success "SSH login integration enabled"
        print_info "KASTATS will now display automatically when users SSH into this server"
    else
        # If SSH integration is disabled, remove existing integration
        if [ -f "${PROFILE_DIR}/kastats.sh" ]; then
            print_info "Removing existing SSH integration..."
            rm -f "${PROFILE_DIR}/kastats.sh"
            print_success "SSH integration removed"
        else
            print_info "SSH login integration skipped"
        fi
    fi
}

show_completion_message() {
    echo ""
    echo -e "${BOLD}${GREEN}┌─────────────────────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${BOLD}${GREEN}│${NC}                          ${BOLD}${WHITE}INSTALLATION COMPLETE!${NC}                         ${BOLD}${GREEN}│${NC}"
    echo -e "${BOLD}${GREEN}└─────────────────────────────────────────────────────────────────────────────┘${NC}"
    echo ""
    echo -e "${BOLD}${WHITE}Installation Summary:${NC}"
    echo -e "${GREEN}✓${NC} Theme: ${THEME_NAME}"
    echo -e "${GREEN}✓${NC} Command: ${BOLD}kastats${NC} (available system-wide)"
    echo -e "${GREEN}✓${NC} Location: ${INSTALL_DIR}/kastats"

    if [ "$ENABLE_SSH_LOGIN" = true ]; then
        echo -e "${GREEN}✓${NC} SSH Login: ${BOLD}Enabled${NC} (shows on SSH login)"
    else
        echo -e "${YELLOW}•${NC} SSH Login: ${BOLD}Disabled${NC}"
    fi

    echo ""
    echo -e "${BOLD}${WHITE}Usage:${NC}"
    echo -e "${CYAN}•${NC} Run manually: ${BOLD}kastats${NC}"
    echo -e "${CYAN}•${NC} Test now: ${BOLD}sudo -u \$USER kastats${NC}"

    if [ "$ENABLE_SSH_LOGIN" = true ]; then
        echo -e "${CYAN}•${NC} SSH users will see KASTATS automatically on login"
        echo ""
        echo -e "${BOLD}${WHITE}To disable SSH login integration later:${NC}"
        echo -e "${YELLOW}•${NC} Remove: ${BOLD}sudo rm ${PROFILE_DIR}/kastats.sh${NC}"
    fi

    echo ""
    echo -e "${BOLD}${WHITE}Repository:${NC} ${BLUE}https://github.com/${GITHUB_USER}/${REPO_NAME}${NC}"
    echo ""
}

check_existing_installation() {
    local existing_installation=false
    local existing_ssh_integration=false

    if [ -f "${INSTALL_DIR}/kastats" ]; then
        existing_installation=true
    fi

    if [ -f "${PROFILE_DIR}/kastats.sh" ]; then
        existing_ssh_integration=true
    fi

    if [ "$existing_installation" = true ] || [ "$existing_ssh_integration" = true ]; then
        echo -e "${YELLOW}⚠${NC} ${BOLD}Existing KASTATS installation detected:${NC}"

        if [ "$existing_installation" = true ]; then
            echo -e "${YELLOW}•${NC} Command: ${BOLD}kastats${NC} (will be replaced)"
        fi

        if [ "$existing_ssh_integration" = true ]; then
            echo -e "${YELLOW}•${NC} SSH Integration: ${BOLD}Enabled${NC} (will be updated)"
        fi

        echo ""
        echo -e "${BOLD}${WHITE}This installation will replace the existing setup.${NC}"
        echo ""
    fi
}

main() {
    print_header

    print_info "Welcome to the KASTATS installer!"
    echo ""

    # Check system requirements
    check_requirements
    echo ""

    # Check for existing installation
    check_existing_installation

    # Get user preferences
    get_theme_choice
    get_ssh_login_choice

    echo ""
    echo -e "${BOLD}${WHITE}Installation Summary:${NC}"
    echo -e "${PURPLE}•${NC} Theme: ${THEME_NAME}"
    echo -e "${PURPLE}•${NC} SSH Integration: $([ "$ENABLE_SSH_LOGIN" = true ] && echo "Enabled" || echo "Disabled")"
    echo ""

    echo -n -e "${BOLD}${WHITE}Proceed with installation? (y/n): ${NC}"
    read -r confirm

    case $confirm in
        [Yy]|[Yy][Ee][Ss])
            echo ""
            ;;
        *)
            print_info "Installation cancelled by user"
            exit 0
            ;;
    esac

    # Perform installation
    download_and_install
    setup_ssh_login

    # Show completion message
    show_completion_message
}

# Cleanup function for safe exit
cleanup() {
    rm -f "/tmp/kastats_temp.sh" 2>/dev/null
}

# Set trap for cleanup on exit
trap cleanup EXIT

main "$@"