# Linux System Monitor (Zenity GUI)

A cross-distro **Bash-based system monitoring tool** with a graphical interface powered by `Zenity`. This tool provides real-time insights about your system such as CPU, RAM, battery, disk, network usage, hardware info, and more — all accessible via a friendly GUI.

---

## Features

- System Overview: Hostname, OS, kernel, architecture, uptime, and more
- CPU: Live usage, temperature, core count, power mode
- RAM: Total usage, available memory
- Disk: Usage details, storage info
- Network: Bandwidth monitoring via `ifstat` or `vnstat`
- Processes: View top running processes
- Battery Status (for laptops)
- Wi-Fi Connected Devices (via `arp-scan`)
- Hardware Details (via `lshw`)
- Simple graphical menu using `Zenity`
- Automatic cross-distro package installer (supports **Debian**, **Ubuntu**, **Arch/Manjaro**, and **Fedora**)

---

## How to Run

1. **Clone or download** the project:
   ```bash
   git clone https://github.com/yourusername/linux-system-monitor.git
   cd linux-system-monitor
   ```
2. **Make the script executable**:
  ```bash
  chmod +x system_monitor.sh
  ```
3. **Run the script**:
  ```bash
  ./system_monitor.sh
  ```
It will:
   - Detect your Linux distribution
   - Install all required packages (via apt, pacman, dnf, or AUR with yay)
   - Launch the Zenity-based GUI menu

## Dependencies

The script automatically installs these if not already present:    
 - zenity
 - lm-sensors
 - acpi
 - arp-scan
 - vnstat
 - gnuplot
 - gtk3 or libgtk-3-dev
 - lshw
 - xdpyinfo
 - ifstat (via AUR on Arch-based distros)

## Supported Distributions
- Debian / Ubuntu
- Arch / Manjaro
- Fedora

## Notes
- For network and hardware-related info, the script uses tools that may require superuser access (e.g., lshw, arp-scan).
- AUR helper yay will be installed automatically on Arch-based systems if not already present.
