#!/bin/bash

# Common Functions for Dev Setup Scripts
# This library provides OS detection and package manager abstraction
# for supporting both Ubuntu/Debian and Rocky Linux/RHEL distributions

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Logging functions
log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Global variables for OS detection
OS_TYPE=""
OS_NAME=""
OS_VERSION=""
PKG_MANAGER=""

# Detect operating system
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS_NAME=$ID
        OS_VERSION=$VERSION_ID

        case "$ID" in
            ubuntu|debian)
                OS_TYPE="debian"
                PKG_MANAGER="apt"
                ;;
            rocky|rhel|centos|fedora)
                OS_TYPE="rhel"
                PKG_MANAGER="dnf"
                # Check if dnf exists, fallback to yum
                if ! command -v dnf &> /dev/null; then
                    PKG_MANAGER="yum"
                fi
                ;;
            *)
                OS_TYPE="unknown"
                PKG_MANAGER="unknown"
                warning "Unknown OS: $ID"
                ;;
        esac
    else
        error "Cannot detect OS: /etc/os-release not found"
        return 1
    fi

    info "Detected OS: $OS_NAME $OS_VERSION ($OS_TYPE)"
    info "Package Manager: $PKG_MANAGER"
    return 0
}

# Update package lists
update_packages() {
    log "Updating package lists..."

    case "$PKG_MANAGER" in
        apt)
            sudo apt-get update
            ;;
        dnf)
            sudo dnf check-update || true
            ;;
        yum)
            sudo yum check-update || true
            ;;
        *)
            error "Unknown package manager: $PKG_MANAGER"
            return 1
            ;;
    esac
}

# Install packages (abstraction layer)
install_package() {
    local packages=("$@")

    log "Installing packages: ${packages[*]}"

    case "$PKG_MANAGER" in
        apt)
            sudo apt-get install -y "${packages[@]}"
            ;;
        dnf)
            sudo dnf install -y "${packages[@]}"
            ;;
        yum)
            sudo yum install -y "${packages[@]}"
            ;;
        *)
            error "Unknown package manager: $PKG_MANAGER"
            return 1
            ;;
    esac
}

# Add repository (OS-specific)
add_repository() {
    local repo_type="$1"
    local repo_data="$2"

    case "$OS_TYPE" in
        debian)
            case "$repo_type" in
                "key-url")
                    wget -q -O - "$repo_data" | sudo apt-key add -
                    ;;
                "repo-line")
                    echo "$repo_data" | sudo tee /etc/apt/sources.list.d/$(basename "$repo_data" | cut -d' ' -f2).list
                    ;;
            esac
            ;;
        rhel)
            case "$repo_type" in
                "rpm-url")
                    sudo rpm --import "$repo_data"
                    ;;
                "repo-file")
                    echo "$repo_data" | sudo tee /etc/yum.repos.d/$(basename "$repo_data" | cut -d'/' -f1).repo
                    ;;
            esac
            ;;
        *)
            error "Unknown OS type: $OS_TYPE"
            return 1
            ;;
    esac
}

# Check if package is installed
is_package_installed() {
    local package="$1"

    case "$PKG_MANAGER" in
        apt)
            dpkg -l "$package" 2>/dev/null | grep -q '^ii'
            ;;
        dnf)
            rpm -q "$package" &>/dev/null
            ;;
        yum)
            rpm -q "$package" &>/dev/null
            ;;
        *)
            return 1
            ;;
    esac
}

# Install dependencies for Chrome (OS-specific)
install_chrome_dependencies() {
    log "Installing Chrome dependencies for $OS_TYPE..."

    case "$OS_TYPE" in
        debian)
            install_package wget gnupg2 apt-transport-https ca-certificates
            ;;
        rhel)
            install_package wget gnupg2 ca-certificates
            ;;
        *)
            error "Unsupported OS type: $OS_TYPE"
            return 1
            ;;
    esac
}

# Install Chrome (OS-specific implementation)
install_chrome_browser() {
    log "Installing Google Chrome for $OS_TYPE..."

    case "$OS_TYPE" in
        debian)
            # Add Google Chrome repository
            log "Adding Google Chrome repository..."
            wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | sudo apt-key add -

            if [ ! -f /etc/apt/sources.list.d/google-chrome.list ]; then
                echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" | sudo tee /etc/apt/sources.list.d/google-chrome.list
            fi

            # Update and install Chrome
            update_packages
            install_package google-chrome-stable
            ;;
        rhel)
            # Add Google Chrome repository
            log "Adding Google Chrome repository..."
            cat <<EOF | sudo tee /etc/yum.repos.d/google-chrome.repo
[google-chrome]
name=google-chrome
baseurl=http://dl.google.com/linux/chrome/rpm/stable/x86_64
enabled=1
gpgcheck=1
gpgkey=https://dl.google.com/linux/linux_signing_key.pub
EOF

            # Install Chrome
            install_package google-chrome-stable
            ;;
        *)
            error "Unsupported OS type: $OS_TYPE"
            return 1
            ;;
    esac

    log "Chrome installed successfully"
}

# Display OS information
show_os_info() {
    echo ""
    log "=== System Information ==="
    log "  OS Name: $OS_NAME"
    log "  OS Version: $OS_VERSION"
    log "  OS Type: $OS_TYPE"
    log "  Package Manager: $PKG_MANAGER"
    echo ""
}

# Export functions for use in other scripts
export -f log
export -f error
export -f warning
export -f info
export -f detect_os
export -f update_packages
export -f install_package
export -f add_repository
export -f is_package_installed
export -f install_chrome_dependencies
export -f install_chrome_browser
export -f show_os_info
