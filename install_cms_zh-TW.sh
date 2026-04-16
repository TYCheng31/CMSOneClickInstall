#!/bin/bash
# 遇到錯誤即停止執行
set -e

# 定義資料庫變數 (請依照需求修改)
DB_USER="cmsuser"
DB_PASS="cms"
DB_NAME="cmsdb"
CMS_DIR="$HOME/cms"
VENV_DIR="$HOME/cms_venv"

echo "[1/6] 更新系統與安裝依賴套件..."
export DEBIAN_FRONTEND=noninteractive
sudo apt-get update
sudo apt-get install -y \
    build-essential openjdk-11-jdk-headless fp-compiler \
    postgresql postgresql-client cppreference-doc-en-html \
    cgroup-lite libcap-dev zip python3.12-dev libpq-dev \
    libcups2-dev libyaml-dev libffi-dev python3-pip \
    git python3.12-venv

echo "[2/6] 下載 CMS 原始碼 (v1.5.0)..."
if [ ! -d "$CMS_DIR" ]; then
    git clone --branch v1.5.0 --single-branch https://github.com/cms-dev/cms.git "$CMS_DIR" --recursive
else
    echo "目錄 $CMS_DIR 已存在，跳過 clone。"
fi

echo "[3/6] 執行 CMS 系統層級環境設定..."
cd "$CMS_DIR"
sudo python3 prerequisites.py install

echo "[4/6] 建立 Python 虛擬環境並安裝套件..."
python3 -m venv "$VENV_DIR"
# 使用虛擬環境內的 pip 和 python 絕對路徑來執行，避免 source 指令在腳本中失效
"$VENV_DIR/bin/pip" install -r requirements.txt
"$VENV_DIR/bin/pip" install setuptools
"$VENV_DIR/bin/python" setup.py install

echo "[5/6] 設定 PostgreSQL 資料庫..."
# 啟動 PostgreSQL 服務 (若尚未啟動)
sudo systemctl start postgresql
# 自動化建立使用者與資料庫
sudo -u postgres psql -c "CREATE USER $DB_USER WITH PASSWORD '$DB_PASS';" || true
sudo -u postgres createdb --owner=$DB_USER $DB_NAME || true
sudo -u postgres psql -d $DB_NAME -c "ALTER SCHEMA public OWNER TO $DB_USER;"
sudo -u postgres psql -d $DB_NAME -c "GRANT SELECT ON pg_largeobject TO $DB_USER;"

echo "========================================"
echo "安裝完成！請記得修改 $CMS_DIR/config/cms.conf 中的資料庫連線字串。"
echo "========================================"

echo "[6/6] CMS 的 cgroup 設定需要重新開機才能完全生效。"
read -p "請問是否現在要重新開機？ (y/N): " REBOOT_CONFIRM
if [[ "$REBOOT_CONFIRM" =~ ^[Yy]$ ]]; then
    sudo reboot
else
    echo "請記得稍後手動重新開機。"
fi

