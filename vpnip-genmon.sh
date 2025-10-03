#!/bin/sh
#
# vpnip-genmon.sh — XFCE Genmon plugin script for LAN/VPN IP monitoring
#
# Features:
# - Shows LAN IP (blue) when no VPN is active.
# - Shows VPN IP (green + VPN icon) when connected.
# - Tooltip displays all interfaces with IPv4 addresses, plus a full list of IPs (IPv4/IPv6).
# - Clicking the text copies the VPN IP to clipboard (requires `xclip` or `wl-clipboard`).
#
# Why this script:
# After updating to xfce4-genmon-plugin 4.3.0, old `.rc` configs stopped working in XFCE panel.
# The default Kali VPN IP script returned empty <txt></txt> when no VPN was present,
# leaving the panel blank. This wrapper provides a consistent output (LAN or VPN),
# with colors, tooltip, and clipboard support.
#
# Usage:
# 1. Copy this file to /usr/local/bin/vpnip-genmon.sh
# 2. Make it executable: sudo chmod +x /usr/local/bin/vpnip-genmon.sh
# 3. In XFCE panel, add a "Generic Monitor" plugin:
#    - Command: /usr/local/bin/vpnip-genmon.sh
#    - Period: 5 (seconds)
#    - Enable "Use single panel row"
#    - Enable "Markup"
# 4. Restart panel: xfce4-panel -r
#
# Author: Denis Dunovski
# License: MIT
#

vpn_raw="$(/usr/share/kali-themes/xfce4-panel-genmon-vpnip.sh 2>/dev/null || true)"

# Extract first IPv4 if present
vpn_ip="$(printf '%s\n' "$vpn_raw" | grep -oE '\b([0-9]{1,3}\.){3}[0-9]{1,3}\b' | head -n1 || true)"

# Interfaces with IPv4 (except lo)
iface_list="$(ip -o -4 addr show 2>/dev/null \
  | awk '$2!="lo"{print $2": "$4}' \
  | sed 's#/.*##' \
  | paste -sd ' | ' -)"
[ -z "$iface_list" ] && iface_list="No IPv4 on interfaces"

# All IP addresses (IPv4 + IPv6)
all_ips="$(hostname -I 2>/dev/null | tr '\n' ' ' | sed 's/[[:space:]]*$//')"
[ -z "$all_ips" ] && all_ips="No IP addresses"

if [ -z "$vpn_ip" ]; then
  # No VPN → show LAN IP
  lan_ip="$(printf '%s' "$all_ips" | awk '{print $1}')"
  printf '<txt><span foreground="deepskyblue">LAN: %s</span></txt>\n' "${lan_ip:-N/A}"
  printf '<tool>Interfaces: %s\nAll IPs: %s</tool>\n' "$iface_list" "$all_ips"
else
  # VPN detected → show icon, green text, and click-to-copy
  printf '<icon>network-vpn-symbolic</icon>\n'
  printf '<txt><span foreground="limegreen">VPN: %s</span></txt>\n' "$vpn_ip"
  printf '<txtclick>sh -c "printf %s | xclip -selection clipboard"</txtclick>\n' "$vpn_ip"
  printf '<tool>VPN IP (click to copy)\nInterfaces: %s\nAll IPs: %s</tool>\n' "$iface_list" "$all_ips"
fi
