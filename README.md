# KASTATS 📊

**Beautiful system information display tool for Linux servers**

KASTATS provides a clean, colorful overview of your system's vital statistics - perfect for SSH login screens and system monitoring.

## ✨ Features

- 🎨 **Two Beautiful Themes**: Sakura (pink) and Sky Blue
- 📊 **Comprehensive System Info**: CPU, memory, disk, network, and more
- 🔄 **Real-time Progress Bars**: Visual usage indicators
- 🔐 **Security Monitoring**: Package updates, failed logins, service status
- ⏰ **Smart Greetings**: Time-based welcome messages
- 👥 **User Awareness**: Shows other logged-in users
- 🔧 **SSH Integration**: Automatic display on login
- 🚀 **Easy Installation**: One-line setup script

## 🎨 Themes

### 🌸 Sakura Theme
Beautiful pink cherry blossom colors with soft pastels and coral accents.

### ☁️ Sky Blue Theme  
Clean sky blue and cloud colors with a professional azure palette.

## 🚀 Quick Installation

**One-line installation:**
```bash
bash <(curl -s https://raw.githubusercontent.com/KeaneAudric20/kastats/main/setup.sh)
```

The installer will:
1. Let you choose between Sakura 🌸 or Sky Blue ☁️ themes
2. Ask if you want SSH login integration
3. Install `kastats` as a system-wide command
4. Set up automatic display on SSH login (optional)

## 📋 Manual Installation

1. **Download your preferred theme:**
   ```bash
   # Sakura theme
   wget https://raw.githubusercontent.com/KeaneAudric20/kastats/main/sakura_kastats.sh
   
   # Sky Blue theme  
   wget https://raw.githubusercontent.com/KeaneAudric20/kastats/main/blue_kastats.sh
   ```

2. **Make executable and install:**
   ```bash
   chmod +x sakura_kastats.sh  # or blue_kastats.sh
   sudo cp sakura_kastats.sh /usr/local/bin/kastats
   ```

3. **Optional: Enable SSH login integration:**
   ```bash
   sudo tee /etc/profile.d/kastats.sh > /dev/null << 'EOF'
   #!/bin/bash
   if [[ $- == *i* ]] && [[ -n "$SSH_CONNECTION" || -n "$SSH_CLIENT" || -n "$SSH_TTY" ]]; then
       if command -v kastats >/dev/null 2>&1; then
           kastats
       fi
   fi
   EOF
   sudo chmod +x /etc/profile.d/kastats.sh
   ```

## 🖥️ Usage

**Run manually:**
```bash
kastats
```

**SSH users will see KASTATS automatically when they log in** (if SSH integration is enabled).

## 📊 What KASTATS Shows

### System Information
- Operating system and kernel version
- Hostname and uptime
- Platform type (bare metal, VM, container)
- Architecture and shell
- Last boot time and reboot reason

### Hardware Status
- CPU model and usage with progress bar
- Memory usage with progress bar  
- Swap usage (if configured)
- Disk usage with progress bar

### Network Information
- Private and public IP addresses
- IPv6 address (if available)

### Security & Updates
- Available security and regular updates
- Last login information
- Failed login attempts count

### System Status
- Load average with intelligent interpretation
- Critical services status
- Disk space warnings
- Time-based greetings

## 🔧 Configuration

### Disable SSH Integration
```bash
sudo rm /etc/profile.d/kastats.sh
```

### Switch Themes
Simply run the installer again and choose a different theme:
```bash
bash <(curl -s https://raw.githubusercontent.com/KeaneAudric20/kastats/main/setup.sh)
```

## 📋 Requirements

- Linux system (Ubuntu, Debian, CentOS, RHEL, Fedora)
- Bash shell
- Basic utilities: `curl`, `bc`, `free`, `df`, `uptime`
- Root/sudo access for installation

The installer automatically handles missing dependencies.

## 🎯 Perfect For

- **Server Administrators**: Instant system overview on SSH login
- **System Monitoring**: Quick health checks
- **Development Servers**: Beautiful welcome screens
- **Production Environments**: Professional system information display

## 🤝 Contributing

Contributions are welcome! Feel free to:
- Report bugs
- Suggest new features  
- Submit pull requests
- Improve documentation

## 📄 License

This project is open source and available under the [GPL-3.0 License](LICENSE).

## 🙏 Acknowledgments

- Inspired by various system information tools
- Built with love for the Linux community
- Thanks to all contributors and users

---

**Made with ❤️ for Linux system administrators**

*Star ⭐ this repo if you find KASTATS useful!*
