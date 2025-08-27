#!/bin/bash
# Install Semaphore as a systemd service (interactive setup for SQLite)

set -e

SEMAPHORE_VERSION="2.16.17"
INSTALL_DIR="/usr/local/bin"
CONFIG_DIR="/etc/semaphore"
USER="ansible"

echo "=== Installing Semaphore $SEMAPHORE_VERSION ==="

# 1. Install prerequisites
sudo apt update
sudo apt install -y wget tar sqlite3

# 2. Create config directory
sudo mkdir -p $CONFIG_DIR
sudo chown $USER:$USER $CONFIG_DIR

# 3. Download Semaphore binary
cd /tmp
wget https://github.com/semaphoreui/semaphore/releases/download/v$SEMAPHORE_VERSION/semaphore_${SEMAPHORE_VERSION}_linux_amd64.tar.gz
tar -xvzf semaphore_${SEMAPHORE_VERSION}_linux_amd64.tar.gz
sudo mv semaphore $INSTALL_DIR/semaphore
sudo chmod +x $INSTALL_DIR/semaphore

# 4. Run interactive setup (user must enter admin credentials, choose SQLite)
echo "=== RUNNING SEMAPHORE SETUP ==="
echo "Please follow the prompts:"
sudo -u $USER $INSTALL_DIR/semaphore setup

# 5. Create systemd service
SERVICE_FILE="/etc/systemd/system/semaphore.service"

echo "=== Creating systemd service ==="
sudo tee $SERVICE_FILE > /dev/null <<EOL
[Unit]
Description=Semaphore Ansible Service
After=network.target

[Service]
Type=simple
ExecStart=$INSTALL_DIR/semaphore server --config=$CONFIG_DIR/config.json
Restart=on-failure
User=$USER
WorkingDirectory=$CONFIG_DIR

[Install]
WantedBy=multi-user.target
EOL

# 6. Enable and start the service
sudo systemctl daemon-reload
sudo systemctl enable semaphore
sudo systemctl start semaphore

# 7. Test if Semaphore is running
echo "=== Semaphore service status ==="
sudo systemctl status semaphore --no-pager

echo "=== Done! Access Semaphore at http://localhost:3000 ==="
echo "Use the admin credentials you set during the setup."
echo "Remember to open port 3000 in your firewall if accessing remotely."
echo "For security, consider setting up a reverse proxy with HTTPS."
echo "To stop the service, use: sudo systemctl stop semaphore"
echo "To start the service, use: sudo systemctl start semaphore"
echo "To check the service status, use: sudo systemctl status semaphore"
echo "To view logs, use: sudo journalctl -u semaphore -f"
echo "To uninstall, stop the service and remove the binary and config directory."
echo "sudo systemctl stop semaphore"
