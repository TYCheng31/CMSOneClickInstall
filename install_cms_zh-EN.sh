#!/bin/bash
# Exit immediately if a command exits with a non-zero status
set -e

# Define database variables (modify as needed)
DB_USER="cmsuser"
DB_PASS="cms"
DB_NAME="cmsdb"
CMS_DIR="$HOME/cms"
VENV_DIR="$HOME/cms_venv"

echo "[1/6] Updating system and installing dependencies..."
export DEBIAN_FRONTEND=noninteractive
sudo apt-get update
sudo apt-get install -y \
    build-essential openjdk-11-jdk-headless fp-compiler \
    postgresql postgresql-client cppreference-doc-en-html \
    cgroup-lite libcap-dev zip python3.12-dev libpq-dev \
    libcups2-dev libyaml-dev libffi-dev python3-pip \
    git python3.12-venv

echo "[2/6] Downloading CMS source code (v1.5.0)..."
if [ ! -d "$CMS_DIR" ]; then
    git clone --branch v1.5.0 --single-branch https://github.com/TYCheng31/cms.git "$CMS_DIR" --recursive
else
    echo "Directory $CMS_DIR already exists, skipping clone."
fi

echo "[3/6] Running CMS system-level prerequisites setup..."
cd "$CMS_DIR"
sudo python3 prerequisites.py install

echo "[4/6] Creating Python virtual environment and installing packages..."
python3 -m venv "$VENV_DIR"
"$VENV_DIR/bin/pip" install "setuptools<70" --force-reinstall
"$VENV_DIR/bin/pip" install -r requirements.txt
"$VENV_DIR/bin/python" setup.py install

echo "[5/6] Configuring PostgreSQL database..."
# Start PostgreSQL service (if not already running)
sudo systemctl start postgresql
# Automate the creation of user and database
sudo -u postgres psql -c "CREATE USER $DB_USER WITH PASSWORD '$DB_PASS';" || true
sudo -u postgres createdb --owner=$DB_USER $DB_NAME || true
sudo -u postgres psql -d $DB_NAME -c "ALTER SCHEMA public OWNER TO $DB_USER;"
sudo -u postgres psql -d $DB_NAME -c "GRANT SELECT ON pg_largeobject TO $DB_USER;"

echo "========================================"
echo "Installation complete! Please remember to update the database connection string in $CMS_DIR/config/cms.conf."
echo "========================================"

echo "[6/6] CMS cgroup settings require a reboot to take full effect."
read -p "Would you like to reboot now? (y/N): " REBOOT_CONFIRM
if [[ "$REBOOT_CONFIRM" =~ ^[Yy]$ ]]; then
    sudo reboot
else
    echo "Please remember to manually reboot later."
fi