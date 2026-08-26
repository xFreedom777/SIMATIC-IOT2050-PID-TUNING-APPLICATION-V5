#!/bin/bash
# ================================================================
# Siemens SIMATIC IOT2050 — 24/7 Kiosk Stability Setup Script
# ================================================================
set -e

echo "==========================================================="
echo " 🛠  Configuring Siemens IOT2050 24/7 Stability Parameters"
echo "==========================================================="

if [ "$EUID" -ne 0 ]; then
  echo "❌ Please run as root (sudo ./setup-247-stability.sh)"
  exit 1
fi

APP_DIR="/opt/pid-tuning-app"
USER_HOME="/root"

# 1. Disable System Idle & Lid Sleep Actions in logind.conf
echo "--> [1/8] Disabling logind sleep & idle actions..."
mkdir -p /etc/systemd/logind.conf.d/
cat << 'EOF' > /etc/systemd/logind.conf.d/247-stability.conf
[Login]
IdleAction=ignore
HandleLidSwitch=ignore
HandleSuspendKey=ignore
HandleHibernateKey=ignore
HandlePowerKey=ignore
EOF
systemctl restart systemd-logind || true

# 2. Disable Kernel Console Blanking
echo "--> [2/8] Disabling Linux kernel console blanking..."
if [ -f /sys/module/kernel/parameters/consoleblank ]; then
  echo 0 > /sys/module/kernel/parameters/consoleblank 2>/dev/null || true
fi
if grep -q "consoleblank" /etc/sysctl.conf; then
  sed -i 's/consoleblank=.*/consoleblank=0/' /etc/sysctl.conf
else
  echo "kernel.consoleblank = 0" >> /etc/sysctl.conf
fi

# 3. Limit Systemd Journal Logs to 100MB (Prevents Disk Exhaustion)
echo "--> [3/8] Configuring Journald log limits (Max 100MB)..."
mkdir -p /etc/systemd/journald.conf.d/
cat << 'EOF' > /etc/systemd/journald.conf.d/limit-size.conf
[Journal]
SystemMaxUse=100M
SystemKeepFree=200M
MaxRetentionSec=1month
EOF
systemctl restart systemd-journald || true

# 4. Generate Production ~/.xinitrc with GPU-disabled & DPMS-off flags
echo "--> [4/8] Installing X11 Kiosk launcher (~/.xinitrc)..."
cat << 'EOF' > "${USER_HOME}/.xinitrc"
#!/bin/bash
# ── Siemens IOT2050 24/7 Kiosk Launcher ──

# Disable Display Power Management (DPMS) & Screen Savers
xset -dpms
xset s off
xset s noblank
xset s 0 0
setterm -blank 0 -powerdown 0 2>/dev/null || true

# Fix mouse cursor styling
xsetroot -cursor_name left_ptr &

# Clear previous Chromium crash locks & restore profiles
rm -rf ~/.config/chromium/Singleton*
rm -rf ~/.config/chromium/Default/WebData*
find ~/.config/chromium -name "Preferences" -exec sed -i 's/"exited_cleanly":false/"exited_cleanly":true/' {} + 2>/dev/null || true
find ~/.config/chromium -name "Preferences" -exec sed -i 's/"exit_type":"Crashed"/"exit_type":"Normal"/' {} + 2>/dev/null || true

# Continuous Kiosk Loop with GPU-disabled flags (prevents ARM driver freeze)
while true; do
  chromium \
    --no-sandbox \
    --disable-dev-shm-usage \
    --no-first-run \
    --password-store=basic \
    --kiosk \
    --start-fullscreen \
    --start-maximized \
    --window-size=1920,1080 \
    --window-position=0,0 \
    --disable-infobars \
    --disable-session-crashed-bubble \
    --disable-gpu \
    --disable-software-rasterizer \
    --disk-cache-size=1 \
    --media-cache-size=1 \
    --js-flags="--max-old-space-size=256" \
    --autoplay-policy=no-user-gesture-required \
    --force-device-scale-factor=1.0 \
    http://localhost:3000/splash.html
  
  sleep 2
done
EOF
chmod +x "${USER_HOME}/.xinitrc"

# 5. RAM Tmpfs Protection & Ext4 Error Policy
echo "--> [5/8] Configuring /etc/fstab for Tmpfs and Ext4 policies..."
sed -i 's/errors=remount-ro/errors=continue/g' /etc/fstab

if ! grep -q "tmpfs /var/log" /etc/fstab; then
  echo "tmpfs /var/log tmpfs defaults,noatime,nosuid,mode=0755,size=100m 0 0" >> /etc/fstab
fi
if ! grep -q "tmpfs /tmp" /etc/fstab; then
  echo "tmpfs /tmp tmpfs defaults,noatime,nosuid,size=100m 0 0" >> /etc/fstab
fi
if ! grep -q "tmpfs /var/tmp" /etc/fstab; then
  echo "tmpfs /var/tmp tmpfs defaults,noatime,nosuid,size=50m 0 0" >> /etc/fstab
fi

# 6. Install Watchdog script
echo "--> [6/8] Installing Self-Healing Watchdog script..."
chmod +x "${APP_DIR}/kiosk-watchdog.sh" 2>/dev/null || true

# 7. Install & Enable Standard Systemd Services
echo "--> [7/8] Registering production Systemd services..."
cp "${APP_DIR}/pid-app.service" /etc/systemd/system/ 2>/dev/null || true
cp "${APP_DIR}/kiosk-watchdog.service" /etc/systemd/system/ 2>/dev/null || true
cp "${APP_DIR}/kiosk.service" /etc/systemd/system/ 2>/dev/null || true

systemctl daemon-reload
systemctl enable pid-app.service || true
systemctl enable kiosk-watchdog.service || true
systemctl enable kiosk.service || true

# 8. Offline Industrial Time Persistence (Restores last known timestamp on boot & saves on shutdown)
echo "--> [8/8] Configuring offline system time persistence..."
# Write boot-time restore service (starts early, restores clock from file)
cat << 'EOF' > /etc/systemd/system/save-last-time.service
[Unit]
Description=Restore System Time from Last Saved Timestamp (Offline NTP)
DefaultDependencies=no
After=local-fs.target
Before=network.target sysinit.target

[Service]
Type=oneshot
RemainAfterExit=no
ExecStart=/bin/sh -c 'if [ -f /etc/last_saved_time ]; then ts=$(cat /etc/last_saved_time); date -s "$ts" >/dev/null 2>&1 && hwclock -w >/dev/null 2>&1 && echo "[OK] System time restored from $ts" || true; fi'

[Install]
WantedBy=sysinit.target
EOF

# Write shutdown-time save service (saves clock before poweroff/reboot)
cat << 'EOF' > /etc/systemd/system/save-time-on-shutdown.service
[Unit]
Description=Save System Time Before Shutdown (Offline NTP Backup)
DefaultDependencies=no
Before=shutdown.target reboot.target halt.target poweroff.target
After=basic.target

[Service]
Type=oneshot
RemainAfterExit=no
ExecStart=/bin/sh -c 'if [ "$(date +%Y)" -ge "2024" ]; then date "+%Y-%m-%d %H:%M:%S" > /etc/last_saved_time && hwclock -w >/dev/null 2>&1 && echo "[OK] System time saved: $(cat /etc/last_saved_time)" || true; fi'

[Install]
WantedBy=halt.target reboot.target shutdown.target poweroff.target
EOF

systemctl daemon-reload
systemctl daemon-reload
systemctl enable save-last-time.service || true
systemctl enable save-time-on-shutdown.service || true
systemctl start save-last-time.service || true
echo "    [OK] Time persistence services installed (boot-restore + shutdown-save)" 

echo "==========================================================="
echo " ✅ 24/7 Stability & Time Persistence configured!"
echo " [INFO] Reboot IOT2050 to start 24/7 mode: reboot"

# 9. Auto-Copy Logs to USB every night at 00:01 (Industrial Auto-Export)
echo "--> [9/9] Installing midnight Auto-Copy cron job..."
cat << 'CRONEOF' > /usr/local/bin/pid-usb-backup.sh
#!/bin/bash
# Midnight Auto-Backup: Copy all PID Log CSV files to USB Flash Drive
LOG=/var/log/pid-usb-backup.log
echo "[$(date '+%Y-%m-%d %H:%M:%S')] 🕛 Auto-Backup Started" >> "$LOG"

# Mount USB (ignore error if already mounted or not present)
mount /dev/sda1 /media/usb 2>/dev/null || true

# Check if USB is actually mounted
if ! mount | grep -q /media/usb; then
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] ⚠️ USB not available. Skipping backup." >> "$LOG"
  exit 0
fi

# Create dated folder on USB
TODAY=$(date '+%Y-%m-%d')
DEST="/media/usb/PID_Logs_Backup/${TODAY}"
mkdir -p "$DEST"

# Copy all CSV files from /opt/pid-tuning-app/logs/
SRC="/opt/pid-tuning-app/logs"
if [ -d "$SRC" ]; then
  COUNT=$(find "$SRC" -name "*.csv" | wc -l)
  cp -u "$SRC"/*.csv "$DEST"/ 2>/dev/null || true
  # Auto-generate Click_To_View_Chart.html inside USB backup folder
  node /opt/pid-tuning-app/generate-usb-viewer.js "$DEST" 2>/dev/null || true
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✅ Copied ${COUNT} files → $DEST" >> "$LOG"
fi

# Sync and Eject
sync
umount /media/usb 2>/dev/null || true
echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✅ Auto-Backup Done. USB Ejected." >> "$LOG"

# Keep log max 500 lines
tail -n 500 "$LOG" > "${LOG}.tmp" && mv "${LOG}.tmp" "$LOG"
CRONEOF
chmod +x /usr/local/bin/pid-usb-backup.sh

# Install systemd timer (replaces crontab - IOT2050 Debian has no cron daemon)
cat << 'TIMEREOF' > /etc/systemd/system/pid-usb-backup.timer
[Unit]
Description=Midnight USB Log Auto-Backup Timer
Requires=pid-usb-backup.service

[Timer]
OnCalendar=*-*-* 00:01:00
Persistent=true

[Install]
WantedBy=timers.target
TIMEREOF

cat << 'SVCEOF' > /etc/systemd/system/pid-usb-backup.service
[Unit]
Description=PID USB Log Auto-Backup
After=local-fs.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/pid-usb-backup.sh
StandardOutput=journal
StandardError=journal
SVCEOF

systemctl daemon-reload
systemctl enable pid-usb-backup.timer || true
systemctl start pid-usb-backup.timer || true
echo "    [OK] Systemd timer installed: USB auto-backup every night at 00:01" 

echo "==========================================================="
