#!/bin/bash
# Define some variables
ODOO_USER="odoo"
ODOO_VERSION="17.0"
ODOO_DATA_DIR=/opt/odoo
ODOO_CONFIGURATION_FOLDER=/etc/odoo
ODOO_LOG_DIR=/var/log/odoo

# Install postgresql and create a specific user
apt install postgresql -y
sudo -u postgres createuser -d -R -S $ODOO_USER

# Download sources from github
adduser --system --group --home $ODOO_DATA_DIR $ODOO_USER
sudo -u $ODOO_USER git clone https://github.com/odoo/odoo.git --depth 1 --branch $ODOO_VERSION $ODOO_DATA_DIR/odoo-server
sudo -u $ODOO_USER mkdir -p $ODOO_DATA_DIR/addons

# Install depedencies
apt install wkhtmltopdf -y
exec $ODOO_DATA_DIR/odoo-server/setup/debinstall.sh

# Create file and folder for configuration
mkdir -p $ODOO_CONFIGURATION_FOLDER
cat > $ODOO_CONFIGURATION_FOLDER/odoo-server.conf <<EOL
[options]
db_host = False
db_port = False
db_user = odoo
db_password = False
admin_passwd = strong_password
addons_path = /opt/odoo/addons/
EOL
chmod 640 $ODOO_CONFIGURATION_FOLDER/odoo-server.conf

# Create folder for logs and config logrotate
mkdir -p $ODOO_LOG_DIR
chown -R $ODOO_USER:$ODOO_USER $ODOO_LOG_DIR
chmod 750 $ODOO_LOG_DIR
cat > /etc/logrotate.d/odoo <<EOL
${ODOO_LOG_DIR}/*.log {
    copytruncate
    missingok
    notifempty
}
EOL

# Create systemd service
cat > /etc/systemd/system/odoo.service <<EOL
[Unit]
Description=Odoo Open Source ERP and CRM
After=network.target

[Service]
Type=simple
User=odoo
Group=odoo
ExecStart=/opt/odoo/odoo-server/odoo-bin --config /etc/odoo/odoo-server.conf --logfile /var/log/odoo/odoo-server.log
KillMode=mixed

[Install]
WantedBy=multi-user.target
EOL

systemctl daemon-reload
systemctl enable --now odoo

exit 0