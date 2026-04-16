# CMS (CMS Online Judge) One Click Install

Combine all package installation steps into a one-click installation. After installation, you only need to configure the settings to use the CMS normally.

## Version 

CMS: v1.5.0 <https://cms-dev.github.io/>
OS: Ubuntu 24.04LTS

## Install

```bash
curl -sSL https://raw.githubusercontent.com/TYCheng31/CMSOneClickInstall/master/install_cms.sh | bash
```

## Modify Database Password

Modify `cms.conf` to set the default database password `cms`:
"database":"postgresql+psycopg2://cmsuser:`cms`@localhost:5432/cmsdb"

```bash
sudo nano /usr/local/etc/cms.conf
```

## Initialize Database

```bash
cd ~/cms_venv/bin
source activate
cmsInitDB
```

## Create Admin Account and Password

```bash
cmsAddAdmin -p YOUR_ADMIN_PASSWORD YOU_ADMIN_ACCOUNT
```

## Access Admin Interface to Add a Contest

```bash
cmsAdminWebServer
```
