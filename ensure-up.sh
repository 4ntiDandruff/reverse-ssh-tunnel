#!/bin/bash
# ensure-up.sh - Pastikan sshd khusus dan reverse tunnel tetap hidup
# Bisa dipasang sebagai cron @reboot atau dijalankan berkala

TUNNEL_DIR="$HOME/reverse-tunnel"
LOG="$TUNNEL_DIR/ensure.log"

log() { echo "$(date): $1" >> "$LOG"; }

# 1. Pastikan sshd khusus jalan di 127.0.0.1:2222
if ! ss -tln 2>/dev/null | grep -q "127.0.0.1:2222"; then
  log "sshd mati, nyalakan..."
  sudo mkdir -p /run/sshd 2>/dev/null
  /usr/sbin/sshd -f "$TUNNEL_DIR/sshd_config"
  log "sshd dinyalakan"
fi

# 2. Pastikan reverse tunnel jalan
if ! pgrep -f "reverse-tunnel.sh" > /dev/null; then
  log "tunnel mati, nyalakan..."
  nohup "$TUNNEL_DIR/reverse-tunnel.sh" > "$TUNNEL_DIR/tunnel.log" 2>&1 &
  log "tunnel dinyalakan"
fi
