#!/bin/bash

# Function to detect the distribution
detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO=$ID
    else
        echo "Error: Cannot detect distribution. /etc/os-release not found."
        exit 1
    fi
}

# Function to check and install required packages
check_packages() {
    detect_distro

    local packages=()
    local aur_packages=()
    local missing_packages=()

    # Define package names based on distribution
    case $DISTRO in
        "debian"|"ubuntu")
            packages=("lm-sensors" "ifstat" "zenity" "gnuplot" "acpi" "arp-scan" "libgtk-3-dev" "vnstat" "lshw" "x11-utils")
            for package in "${packages[@]}"; do
                if ! dpkg -l | grep -qw "$package"; then
                    missing_packages+=("$package")
                fi
            done
            if [ ${#missing_packages[@]} -gt 0 ]; then
                echo "Missing packages: ${missing_packages[*]}"
                echo "Installing missing packages..."
                sudo apt-get update
                if sudo apt-get install -y "${missing_packages[@]}"; then
                    echo "Packages installed successfully."
                else
                    echo "Error: Failed to install some packages. Please install them manually."
                    exit 1
                fi
            else
                echo "ALL REQUIRED PACKAGES ARE ALREADY INSTALLED."
            fi
            ;;
        "arch"|"manjaro")
            packages=("lm-sensors" "zenity" "gnuplot" "acpi" "arp-scan" "gtk3" "vnstat" "lshw" "xorg-xdpyinfo")
            aur_packages=("ifstat")  # Packages that might be in the AUR
            # Check packages in the main repositories
            for package in "${packages[@]}"; do
                if ! pacman -Qs "$package" >/dev/null; then
                    missing_packages+=("$package")
                fi
            done
            # Install missing packages from main repositories
            if [ ${#missing_packages[@]} -gt 0 ]; then
                echo "Missing packages (main repos): ${missing_packages[*]}"
                echo "Installing missing packages..."
                sudo pacman -Syu --noconfirm
                if sudo pacman -S --noconfirm "${missing_packages[@]}"; then
                    echo "Packages from main repos installed successfully."
                else
                    echo "Error: Failed to install some packages from main repos. Trying AUR..."
                fi
            fi
            # Check and install AUR packages
            missing_packages=()
            for package in "${aur_packages[@]}"; do
                if ! pacman -Qs "$package" >/dev/null; then
                    missing_packages+=("$package")
                fi
            done
            if [ ${#missing_packages[@]} -gt 0 ]; then
                echo "Missing packages (AUR): ${missing_packages[*]}"
                echo "Installing AUR packages using yay..."
                if ! command -v yay >/dev/null; then
                    echo "yay not found. Installing yay..."
                    sudo pacman -S --noconfirm base-devel git
                    git clone https://aur.archlinux.org/yay.git /tmp/yay
                    cd /tmp/yay
                    makepkg -si --noconfirm
                    cd -
                fi
                if yay -S --noconfirm "${missing_packages[@]}"; then
                    echo "AUR packages installed successfully."
                else
                    echo "Error: Failed to install some AUR packages. Please install them manually."
                    exit 1
                fi
            fi
            if [ ${#missing_packages[@]} -eq 0 ]; then
                echo "ALL REQUIRED PACKAGES ARE ALREADY INSTALLED."
            fi
            ;;
        "fedora")
            packages=("lm-sensors" "ifstat" "zenity" "gnuplot" "acpi" "arp-scan" "gtk3-devel" "vnstat" "lshw" "xorg-x11-utils")
            for package in "${packages[@]}"; do
                if ! rpm -q "$package" >/dev/null; then
                    missing_packages+=("$package")
                fi
            done
            if [ ${#missing_packages[@]} -gt 0 ]; then
                echo "Missing packages: ${missing_packages[*]}"
                echo "Installing missing packages..."
                if sudo dnf install -y "${missing_packages[@]}"; then
                    echo "Packages installed successfully."
                else
                    echo "Error: Failed to install some packages. Please install them manually."
                    exit 1
                fi
            else
                echo "ALL REQUIRED PACKAGES ARE ALREADY INSTALLED."
            fi
            ;;
        *)
            echo "Error: Unsupported distribution: $DISTRO"
            exit 1
            ;;
    esac
}

# Function to display system information
system_info() {
    echo "Hostname: $(hostname)"
    echo "OS: $(grep '^PRETTY_NAME=' /etc/os-release | cut -d'"' -f2)"
    echo "Kernel: $(uname -sr)"
    echo "Architecture: $(uname -m)"
    if command -v xdpyinfo >/dev/null; then
        echo "Resolution: $(xdpyinfo | grep dimensions | awk '{print $2}')"
    else
        echo "Resolution: Not available (xdpyinfo not found)"
    fi
    echo "Shell: $SHELL"
    echo "Uptime: $(uptime -p)"
    detect_distro
    case $DISTRO in
        "debian"|"ubuntu")
            echo "Total Installed Packages: $(dpkg-query -f '${binary:Package}\n' -W | wc -l)"
            ;;
        "arch"|"manjaro")
            echo "Total Installed Packages: $(pacman -Q | wc -l)"
            ;;
        "fedora")
            echo "Total Installed Packages: $(rpm -qa | wc -l)"
            ;;
        *)
            echo "Total Installed Packages: Not available (unsupported distribution)"
            ;;
    esac
    echo "CPU: $(lscpu | grep 'Model name' | awk -F ': ' '{print $2}')"
    echo "CPU Cores: $(lscpu | grep '^CPU(s):' | awk '{print $2}')"
}

# Function to display CPU usage
function cpu_usage() {
    echo "CPU Usage: $(top -bn1 | grep 'Cpu(s)' | sed 's/.*, *\([0-9.]*\)%.*id.*/\1/' | awk '{print 100 - $1"%"}')"
}

# Function to display CPU temperature
function cpu_temperature() {
    if command -v sensors >/dev/null; then
        echo "CPU Temperature: $(sensors | grep 'Package id 0' | awk '{print $4}')"
    else
        echo "CPU Temperature: Not available"
    fi
}

# Function to display RAM usage
function ram_usage() {
    echo "RAM Usage: $(free | grep Mem | awk '{print $3/$2 * 100.0"%"}')"
}

# Function to display available RAM
function available_ram() {
    echo "Available RAM: $(free -h | grep Mem | awk '{print $7}')"
}

# Function to display network usage
function network_usage() {
    if command -v ifstat >/dev/null; then
        ifstat -b -t 1 1
    elif command -v vnstat >/dev/null; then
        vnstat
    else
        echo "Network Usage: Not available (ifstat or vnstat command not found)"
    fi
}

# Function to display disk usage
function disk_usage() {
    echo "Disk Usage: $(df -h | awk 'NR==2{printf "Total: %s, Used: %s, Free: %s", $2, $3, $4}')"
}

# Function to display storage device information
function storage_info() {
    lsblk -o NAME,SIZE,MODEL,MOUNTPOINT
}

# Function to display CPU power mode
function cpu_power_mode() {
    echo "CPU Power Mode:"
    for file in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
        echo "$(basename $(dirname $file)): $(cat $file)"
    done
}

# Function to display top processes
function top_processes() {
    top -b -n 1 | sed '1,7d'
}

# Function to display hardware information
function hardware_info() {
    if command -v lshw >/dev/null; then
        sudo lshw -short
    else
        echo "Hardware info: Not available (lshw command not found)"
    fi
}

# Function to display battery status
function battery_status() {
    if command -v acpi >/dev/null; then
        if acpi -i >/dev/null; then
            acpi -i
        else
            echo "Battery status: No battery information available"
        fi
    else
        echo "Battery status: Not available (acpi command not found)"
    fi
}

# Function to display Wi-Fi connected devices
function wifi_connected_devices() {
    if command -v arp-scan >/dev/null; then
        sudo arp-scan --localnet
    else
        echo "Wi-Fi Connected Devices: Not available (arp-scan command not found)"
    fi
}

# Function to display GUI menu
function gui_menu() {
    if ! command -v zenity >/dev/null; then
        echo "Error: zenity is required but not installed."
        exit 1
    fi

    while true; do
        CHOICE=$(zenity --list --title="System Monitor" --column="Action" \
                        --width=400 --height=600 \
                        "Refresh" \
                        "System Info" \
                        "CPU Usage" \
                        "CPU Temperature" \
                        "RAM Usage" \
                        "Available RAM" \
                        "Network Usage" \
                        "Disk Usage" \
                        "Storage Info" \
                        "CPU Power Mode" \
                        "Processes" \
                        "Hardware Info" \
                        "Battery Status" \
                        "Wi-Fi Connected Devices" \
                        "Exit")

        case $CHOICE in
            "Refresh")
                continue
                ;;
            "System Info")
                system_info | zenity --text-info --title="SYSTEM INFO" --width=500 --height=400 --ok-label="Close"
                ;;
            "CPU Usage")
                cpu_usage | zenity --text-info --title="CPU USAGE" --width=300 --height=100 --ok-label="Close"
                ;;
            "CPU Temperature")
                cpu_temperature | zenity --text-info --title="CPU Temperature" --width=300 --height=100 --ok-label="Close"
                ;;
            "RAM Usage")
                ram_usage | zenity --text-info --title="RAM USAGE" --width=300 --height=100 --ok-label="Close"
                ;;
            "Available RAM")
                available_ram | zenity --text-info --title="AVAILABLE RAM" --width=300 --height=100 --ok-label="Close"
                ;;
            "Network Usage")
                network_usage | zenity --text-info --title="Network Usage" --width=500 --height=400 --ok-label="Close"
                ;;
            "Disk Usage")
                disk_usage | zenity --text-info --title="Disk Usage" --width=300 --height=100 --ok-label="Close"
                ;;
            "Storage Info")
                storage_info | zenity --text-info --title="STORAGE INFO" --width=500 --height=400 --ok-label="Close"
                ;;
            "CPU Power Mode")
                cpu_power_mode | zenity --text-info --title="CPU Power Mode" --width=500 --height=400 --ok-label="Close"
                ;;
            "Processes")
                top_processes | zenity --text-info --title="Top Processes" --width=600 --height=400 --ok-label="Close"
                ;;
            "Hardware Info")
                hardware_info | zenity --text-info --title="Hardware Info" --width=600 --height=400 --ok-label="Close"
                ;;
            "Battery Status")
                battery_status | zenity --text-info --title="Battery Status" --width=400 --height=300 --ok-label="Close"
                ;;
            "Wi-Fi Connected Devices")
                wifi_connected_devices | zenity --text-info --title="Wi-Fi Connected Devices" --width=600 --height=400 --ok-label="Close"
                ;;
            "Exit")
                break
                ;;
        esac
    done
}

# Call the functions
check_packages
gui_menu
