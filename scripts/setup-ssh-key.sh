#!/bin/bash

# SSH Key Setup Script for GitHub
# This script generates SSH keys and helps with GitHub configuration

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[SSH Setup]${NC} $1"
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

# Check for existing SSH keys
check_existing_keys() {
    log "Checking for existing SSH keys..."

    if [ -f "$HOME/.ssh/id_ed25519" ] || [ -f "$HOME/.ssh/id_rsa" ]; then
        warning "Existing SSH keys found:"
        ls -la "$HOME/.ssh/"id_* 2>/dev/null | grep -v '.pub' || true
        echo ""
        read -p "Do you want to create a new key? [y/N]: " create_new
        if [[ ! "$create_new" =~ ^[Yy]$ ]]; then
            log "Using existing keys"
            return 1
        fi
    fi
    return 0
}

# Generate SSH key
generate_ssh_key() {
    log "Generating SSH key..."

    # Get user email for the key
    read -p "Enter your email (for key identification): " user_email

    if [ -z "$user_email" ]; then
        warning "No email provided, using default"
        user_email="user@wsl2"
    fi

    # Choose key type
    echo ""
    echo "Choose SSH key type:"
    echo "1) ED25519 (recommended, modern, secure)"
    echo "2) RSA 4096 (traditional, widely compatible)"
    read -p "Enter your choice [1-2]: " key_type

    case $key_type in
        1)
            KEY_FILE="$HOME/.ssh/id_ed25519"
            log "Generating ED25519 key..."
            ssh-keygen -t ed25519 -C "$user_email" -f "$KEY_FILE"
            ;;
        2)
            KEY_FILE="$HOME/.ssh/id_rsa"
            log "Generating RSA 4096 key..."
            ssh-keygen -t rsa -b 4096 -C "$user_email" -f "$KEY_FILE"
            ;;
        *)
            error "Invalid choice, defaulting to ED25519"
            KEY_FILE="$HOME/.ssh/id_ed25519"
            ssh-keygen -t ed25519 -C "$user_email" -f "$KEY_FILE"
            ;;
    esac

    log "✓ SSH key generated: $KEY_FILE"
}

# Start SSH agent and add key
setup_ssh_agent() {
    log "Setting up SSH agent..."

    # Start SSH agent if not running
    if [ -z "$SSH_AUTH_SOCK" ]; then
        eval "$(ssh-agent -s)"
    fi

    # Add the key to the agent
    if [ -f "$KEY_FILE" ]; then
        ssh-add "$KEY_FILE"
        log "✓ SSH key added to agent"
    fi

    # Add SSH agent startup to bashrc
    if ! grep -q 'ssh-agent' "$HOME/.bashrc"; then
        cat >> "$HOME/.bashrc" << 'EOF'

# Start SSH agent
if [ -z "$SSH_AUTH_SOCK" ]; then
    eval "$(ssh-agent -s)" > /dev/null
    ssh-add ~/.ssh/id_ed25519 2>/dev/null || ssh-add ~/.ssh/id_rsa 2>/dev/null || true
fi
EOF
        log "✓ SSH agent startup added to ~/.bashrc"
    fi
}

# Display key fingerprints
show_fingerprints() {
    log ""
    log "=== SSH Key Fingerprints ==="

    for key in "$HOME/.ssh/"id_*; do
        if [[ "$key" != *.pub ]]; then
            if [ -f "$key" ]; then
                echo ""
                info "Key: $(basename $key)"
                echo "SHA256:"
                ssh-keygen -lf "$key"
                echo "MD5:"
                ssh-keygen -E md5 -lf "$key"
            fi
        fi
    done
}

# Display public key for GitHub
show_public_key() {
    log ""
    log "=== Public Key for GitHub ==="

    if [ -f "${KEY_FILE}.pub" ]; then
        echo ""
        cat "${KEY_FILE}.pub"
        echo ""
        info "Copy the above public key to add it to GitHub"
    fi
}

# Instructions for GitHub
github_instructions() {
    log ""
    log "=== GitHub Setup Instructions ==="
    echo ""
    echo "To add your SSH key to GitHub:"
    echo "1. Copy your public key (shown above)"
    echo "2. Go to: https://github.com/settings/ssh/new"
    echo "3. Paste the key and give it a title (e.g., 'WSL2 Dev Environment')"
    echo "4. Click 'Add SSH key'"
    echo ""
    info "Note: GitHub now uses SHA256 fingerprints by default"
    info "MD5 fingerprints are shown above for reference only"
    echo ""

    read -p "Press Enter when you've added the key to GitHub..."

    # Test GitHub connection
    log "Testing GitHub connection..."
    if ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
        log "✓ GitHub authentication successful!"
    else
        warning "GitHub authentication test inconclusive"
        info "Try: ssh -T git@github.com"
    fi
}

# Configure git
configure_git() {
    log ""
    read -p "Do you want to configure git user settings? [Y/n]: " config_git

    if [[ ! "$config_git" =~ ^[Nn]$ ]]; then
        read -p "Enter your Git username: " git_username
        read -p "Enter your Git email: " git_email

        if [ -n "$git_username" ]; then
            git config --global user.name "$git_username"
            log "✓ Git username set: $git_username"
        fi

        if [ -n "$git_email" ]; then
            git config --global user.email "$git_email"
            log "✓ Git email set: $git_email"
        fi
    fi
}

# Main execution
main() {
    log "=== SSH Key Setup for GitHub ==="

    # Create .ssh directory if it doesn't exist
    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"

    if check_existing_keys; then
        generate_ssh_key
    else
        # Use existing key
        if [ -f "$HOME/.ssh/id_ed25519" ]; then
            KEY_FILE="$HOME/.ssh/id_ed25519"
        elif [ -f "$HOME/.ssh/id_rsa" ]; then
            KEY_FILE="$HOME/.ssh/id_rsa"
        fi
    fi

    setup_ssh_agent
    show_fingerprints
    show_public_key
    github_instructions
    configure_git

    log ""
    log "=== SSH Key Setup Complete ==="
    log ""
    log "Your SSH key is ready to use with GitHub"
    log "Test connection: ssh -T git@github.com"
    log "Clone repos using: git clone git@github.com:username/repo.git"
}

main "$@"
