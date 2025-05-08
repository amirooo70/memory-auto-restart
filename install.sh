#!/bin/bash

# مرحله ۱: ساخت res.sh
echo "Creating /root/res.sh ..."
cat << 'EOF' > /root/res.sh
#!/bin/bash
cd ~/Marzban-node
docker compose down --remove-orphans
docker compose up -d
EOF

chmod +x /root/res.sh
echo "res.sh created and made executable."

# مرحله ۲: دریافت آستانه رم از کاربر
read -p "Enter RAM usage threshold (in percent, e.g. 70): " THRESHOLD

# بررسی ورودی
if ! [[ "$THRESHOLD" =~ ^[0-9]+$ ]] || [ "$THRESHOLD" -le 0 ] || [ "$THRESHOLD" -ge 100 ]; then
    echo "Invalid input. Please enter a number between 1 and 99."
    exit 1
fi

# مرحله ۳: ساخت memory_watch.sh با آستانه دلخواه
echo "Creating memory_watch.sh with threshold $THRESHOLD%..."
cat << EOF > /root/memory_watch.sh
#!/bin/bash

THRESHOLD=$THRESHOLD
INTERVAL=5
LOG_FILE="/var/log/memory_watch.log"
ALREADY_TRIGGERED=false

echo "Memory monitor started at \$(date)" >> "\$LOG_FILE"

while true; do
    USAGE=\$(free | awk '/Mem:/ {printf("%.0f", \$3/\$2 * 100)}')

    if [ "\$USAGE" -gt "\$THRESHOLD" ]; then
        if [ "\$ALREADY_TRIGGERED" = false ]; then
            echo "\$(date '+%Y-%m-%d %H:%M:%S') - Memory usage: \${USAGE}% - Running res.sh" >> "\$LOG_FILE"
            /root/res.sh
            ALREADY_TRIGGERED=true
        fi
    else
        ALREADY_TRIGGERED=false
    fi

    sleep "\$INTERVAL"
done
EOF

chmod +x /root/memory_watch.sh
echo "memory_watch.sh created and made executable."

# مرحله ۴: ساخت فایل سرویس systemd
echo "Creating systemd service..."
cat << EOF > /etc/systemd/system/memory-watch.service
[Unit]
Description=Memory Usage Watcher
After=network.target

[Service]
ExecStart=/root/memory_watch.sh
Restart=always
RestartSec=5
User=root

[Install]
WantedBy=multi-user.target
EOF

# مرحله ۵: فعال‌سازی و اجرای سرویس
systemctl daemon-reload
systemctl enable memory-watch.service
systemctl start memory-watch.service

echo "✅ Setup complete. memory-watch.service is now running."
