#!/usr/bin/env bash
#######################################################################################################################################
# Programa .....: install_zabbix.sh
# Data Criação .: 06/01/2026
# Descrição ....: Realiza a instalação automática do Zabbix Server no modo All-in-One com TimescaleDB 
#                 em sistemas RHEL-like (Rocky Linux / Alma Linux).
# Autor ........: Cleiton Maia
# Modo de Uso...: ./path/do/script/install_zabbix.sh [hostname] [database] [user] [password]
#######################################################################################################################################

#-----[ Environment Variables ]-------------------------------------------------------------------------------------------------------#
zbxHostname="brspappzbx01"
zbxDatabase="db_monitor"
zbxUser="uzbxmonitor"
zbxPassword="9TDRtVCQj5ndSJuqhUBRV9etCXX7zr"
ipLocal=$(ip -br a | awk '$1!="lo" && $3 ~ /^[0-9]/ {print $3; exit}' | cut -d/ -f1)
zbxFileConfig="/etc/zabbix/zabbix_server.conf"

#-----[ System Function ]-------------------------------------------------------------------------------------------------------------#
functionBanner() {
  echo   ""
  echo   "╔════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╗"
  echo   "║                                                                                                                        ║"
  printf "║$(tput bold) %-118s $(tput sgr0)║\n" "$@"
  echo   "║                                                                                                                        ║"
  echo   "╚════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╝"
  echo ""
}

show_help() {
  echo
  echo "Uso:"
  echo "  $0 [opções]"
  echo
  echo "Opções:"
  echo "  --host       Nome do host Zabbix"
  echo "  --db         Nome do banco de dados"
  echo "  --user       Usuário do banco"
  echo "  --password   Senha do banco"
  echo "  --help       Exibe esta ajuda"
  echo
  echo "Exemplos:"
  echo "  $0"
  echo "  $0 --host serverzabbix"
  echo "  $0 --host serverzabbix --password MinhaSenhaForte#123"
  echo
  exit 0
}

#-----[ Validation's ]--------------------------------------------------------------------------------------------------------------#
if [[ ! -d /storage/postgres/data ]]; then
  mkdir -p /storage/postgres/data
fi

while [[ $# -gt 0 ]]; do
  case "$1" in
    --host)
      zbxHostname="$2"
      shift 2
      ;;
    --db)
      zbxDatabase="$2"
      shift 2
      ;;
    --user)
      zbxUser="$2"
      shift 2
      ;;
    --password)
      zbxPassword="$2"
      shift 2
      ;;
    --help|-h)
      show_help
      ;;
    *)
      echo "❌ Parâmetro inválido: $1"
      echo "Use ./$0 --help para ver as opções disponíveis."
      exit 1
      ;;
  esac
done

functionBanner "Parameters used in the installation" \
               "" \
               "Hostname ..........: ${zbxHostname}" \
               "Database ..........: ${zbxDatabase}" \
               "User ..............: ${zbxUser}" \
               "Password ..........: ${zbxPassword}" \
               "IP Local ..........: ${ipLocal}" \
               "" \
               "Se está tudo correto, a instalação será iniciada em 10 segundos..."
               sleep 10

#-----[ Main Procedure ]--------------------------------------------------------------------------------------------------------------#
functionBanner "Automated Installation of Zabbix Server 7.0" \
               "Supported Operating Systems RHEL-LIKE v9" \
               "" \
               "Created: Cleiton Maia <cleiton.maia@pm.me>"
               sleep 3

functionBanner "Hostname definition and /etc/hosts configuration"
  hostnamectl set-hostname "${zbxHostname}"
  echo -e "${ipLocal}\t ${zbxHostname}\t ${zbxHostname}.local.lab" >> /etc/hosts

functionBanner "Configuring SELinux"
  sed -i "s/SELINUX=enforcing/SELINUX=disabled/" /etc/selinux/config
  setenforce 0

functionBanner "Configuring Firewall"
  firewall-cmd --add-port={80,10051,10050}/tcp --permanent
  firewall-cmd --add-port=162/udp --permanent
  firewall-cmd --reload
  # firewall-cmd --list-all

functionBanner "Installing English Language Pack"
  dnf install -y glibc-langpack-en

functionBanner "Installing PostgreSQL Repository"
  yum -y install https://download.postgresql.org/pub/repos/yum/reporpms/EL-9-x86_64/pgdg-redhat-repo-latest.noarch.rpm
  dnf -y module disable postgresql

functionBanner "Installing PostgreSQL Server and Client"
  dnf -y install postgresql17 postgresql17-server

functionBanner "Additional PostgreSQL settings"
  echo "Create override to set PGDATA"
  mkdir -p /etc/systemd/system/postgresql-17.service.d
  touch /etc/systemd/system/postgresql-17.service.d/override.conf
  echo "[Service]" >> /etc/systemd/system/postgresql-17.service.d/override.conf
  echo "Environment=PGDATA=/storage/postgres/data/" >> /etc/systemd/system/postgresql-17.service.d/override.conf
  systemctl daemon-reload
  echo "Initializing PostgreSQL Database Cluster"
  mkdir -p /storage/postgres/data
  chown postgres:postgres /storage/postgres/data
  /usr/pgsql-17/bin/postgresql-17-setup initdb
  # Backup original pg_hba.conf e postgresql.conf
  cp /storage/postgres/data/pg_hba.conf /storage/postgres/data/pg_hba.conf.bkp
  cp /storage/postgres/data/postgresql.conf /storage/postgres/data/postgresql.conf.bkp

  sed -i "s/ident/md5/g" /storage/postgres/data/pg_hba.conf
  echo -e "host\t${zbxDatabase}\t${zbxUser}\t${ipLocal}/32\tmd5" >> /storage/postgres/data/pg_hba.conf

  echo -e "host\t${zbxDatabase}\tzbx_monitor\t0.0.0.0/0\tmd5" >> /storage/postgres/data/pg_hba.conf

  sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" /storage/postgres/data/postgresql.conf
  chown postgres:postgres /storage/postgres/data/*
  sudo -u postgres psql -c "SELECT pg_reload_conf();" 2>/dev/null

functionBanner "Starting the PostgreSQL service"
  systemctl enable --now postgresql-17

functionBanner "Database creation: ${zbxDatabase} and user: ${zbxUser} of Zabbix"
  sudo -u postgres psql -c "CREATE USER ${zbxUser} SUPERUSER PASSWORD '$zbxPassword'" 2>/dev/null
  sudo -u postgres createdb -O "${zbxUser}" -E Unicode -T template0 "${zbxDatabase}" 2>/dev/null
  
  sudo -u postgres psql -c "CREATE USER zbx_monitor WITH ENCRYPTED PASSWORD '$zbxPassword'" 2>/dev/null

functionBanner "Installing Zabbix 7 Repository"
  rpm --import https://repo.zabbix.com/RPM-GPG-KEY-ZABBIX
  rpm -Uvh https://repo.zabbix.com/zabbix/7.0/rocky/9/x86_64/zabbix-release-latest-7.0.el9.noarch.rpm
  dnf clean all

functionBanner "Installing Zabbix Server Packages"
  dnf -y install zabbix-server-pgsql zabbix-sql-scripts

functionBanner "Configuring the database schema ${zbxDatabase}"
  zcat /usr/share/zabbix-sql-scripts/postgresql/server.sql.gz | sudo -u postgres PGPASSWORD="$zbxPassword" psql -hlocalhost -U"$zbxUser" -d"$zbxDatabase" 2>/dev/null

functionBanner "Configuring the Zabbix Server"
  cp /etc/zabbix/zabbix_server.conf /etc/zabbix/zabbix_server.conf.bkp
  # Debug e timeout
  sed -i \
    -e 's|^[#[:space:]]*DebugLevel=.*|DebugLevel=3|' \
    -e 's|^[#[:space:]]*Timeout=.*|Timeout=30|' \
    "$zbxFileConfig"
  # Banco de dados
  sed -i \
    -e "s|^[#[:space:]]*DBHost=.*|DBHost=${zbxHostname}|" \
    -e "s|^[#[:space:]]*DBName=.*|DBName=${zbxDatabase}|" \
    -e "s|^[#[:space:]]*DBUser=.*|DBUser=${zbxUser}|" \
    -e "s|^[#[:space:]]*DBPassword=.*|DBPassword=${zbxPassword}|" \
    "$zbxFileConfig"

functionBanner "Starting the Zabbix service"
  systemctl enable --now zabbix-server

functionBanner "Installing Zabbix Frontend Packages"
  dnf -y install zabbix-web-pgsql zabbix-nginx-conf

functionBanner "Configuring PHP"
  echo "php_value[date.timezone] = America/Sao_Paulo" >> /etc/php-fpm.d/zabbix.conf

functionBanner "Configuring web setup"
  tee /etc/zabbix/web/zabbix.conf.php <<EOL
<?php
    \$DB["TYPE"] = "POSTGRESQL";
    \$DB["SERVER"] = "$zbxHostname";
    \$DB["PORT"] = "5432";
    \$DB["DATABASE"] = "$zbxDatabase";
    \$DB["USER"] = "$zbxUser";
    \$DB["PASSWORD"] = "$zbxPassword";
    \$DB["SCHEMA"] = "";
    \$DB["ENCRYPTION"] = false;
    \$DB["KEY_FILE"] = "";
    \$DB["CERT_FILE"] = "";
    \$DB["CA_FILE"] = "";
    \$DB["VERIFY_HOST"] = false;
    \$DB["CIPHER_LIST"] = "";
    \$DB["VAULT_URL"] = "";
    \$DB["VAULT_DB_PATH"] = "";
    \$DB["VAULT_TOKEN"] = "";
    \$DB["DOUBLE_IEEE754"] = true;
    \$ZBX_SERVER = "$zbxHostname";
    \$ZBX_SERVER_PORT = "10051";
    \$ZBX_SERVER_NAME = "ACME Local Lab";
    \$IMAGE_FORMAT_DEFAULT = IMAGE_FORMAT_PNG;
?>
EOL

functionBanner "Configuring NGINX for Zabbix on port 80"
  sed -i "s/#        listen          8080;/        listen 80 default_server;\\n        listen [::]:80 default_server;/" /etc/nginx/conf.d/zabbix.conf
  sed -i "s/#        server_name     example.com;/        server_name _;/" /etc/nginx/conf.d/zabbix.conf
  sed -i "/.*listen.*/d" /etc/nginx/nginx.conf
  sed -i "/.*server_name.*/d" /etc/nginx/nginx.conf

functionBanner "Initializing the NGINX and PHP-FPM services"
  systemctl enable --now php-fpm
  sleep 5
  systemctl enable --now nginx

functionBanner "Installing Zabbix Agent 2 for monitoring the Zabbix Server"
  dnf -y install zabbix-agent2 zabbix-agent2-plugin-postgresql

functionBanner "Configuring the Zabbix Agent 2"
  sed -i -e "s|^Server=.*|Server=${zbxHostname}|" \
        -e "s|^ServerActive=.*|ServerActive=${zbxHostname}|" \
        -e "s|^Hostname=.*|Hostname=${zbxHostname}|" \
        -e "s|# DebugLevel=3|DebugLevel=3|" \
        -e "s|# RefreshActiveChecks=5|RefreshActiveChecks=120|" \
        -e "s|# Timeout=3|Timeout=3|" \
        /etc/zabbix/zabbix_agent2.conf

functionBanner "Initializing the Zabbix Agent 2 service"
  systemctl enable --now zabbix-agent2

functionBanner "Installation of TimescaleDB repositories"
  tee /etc/yum.repos.d/timescale_timescaledb.repo <<EOL
[timescale_timescaledb]
name=timescale_timescaledb
baseurl=https://packagecloud.io/timescale/timescaledb/el/$(rpm -E %{rhel})/\$basearch
repo_gpgcheck=1
gpgcheck=0
enabled=1
gpgkey=https://packagecloud.io/timescale/timescaledb/gpgkey
sslverify=1
sslcacert=/etc/pki/tls/certs/ca-bundle.crt
metadata_expire=300
EOL

functionBanner "Installation of TimescaleDB packages"
  dnf -y install timescaledb-2-postgresql-17-2.18.0-0.el9.x86_64 timescaledb-2-loader-postgresql-17-2.18.0-0.el9.x86_64

functionBanner "Stopping Zabbix Server"
  systemctl stop zabbix-server

functionBanner "Additional PostgreSQL settings for TimescaleDB"
  echo "shared_preload_libraries = 'timescaledb'" >> /storage/postgres/data/postgresql.conf
  sudo sed -i "s/max_connections = 20/max_connections = 50/" /storage/postgres/data/postgresql.conf
  echo "timescaledb.license=timescale" >> /storage/postgres/data/postgresql.conf

functionBanner "Initializing and configuring PostgreSQL"
  sudo systemctl restart postgresql-17
  sudo -u postgres timescaledb-tune --conf-path=/storage/postgres/data/postgresql.conf --quiet --yes --pg-config=/usr/pgsql-17/bin/pg_config
  echo "CREATE EXTENSION IF NOT EXISTS timescaledb CASCADE;" | sudo -u postgres psql "${zbxDatabase}" 2>/dev/null
  sudo systemctl restart postgresql-17

functionBanner "Migration of the zabbix schema to TimescaleDB"
  cat /usr/share/zabbix-sql-scripts/postgresql/timescaledb/schema.sql | sudo -u postgres psql "${zbxDatabase}"

functionBanner "Initializing the migrated system"
  systemctl start zabbix-server
  sleep 5
  systemctl restart php-fpm
  sleep 5
  systemctl restart nginx

functionBanner "Updating Zabbix Server host and IP in the Zabbix Database"
  export PGPASSWORD="$zbxPassword"
  idHostZabbix=$(psql -h"${zbxHostname}" -p5432 -d"${zbxDatabase}" -U"${zbxUser}" -w -Atc "SELECT hostid FROM hosts WHERE host = 'Zabbix server' ;")
  psql -h "$zbxHostname" -p 5432 -d "$zbxDatabase" -U "$zbxUser" -w -c "UPDATE hosts SET host = '${zbxHostname}', name = '${zbxHostname}', name_upper = UPPER('$zbxHostname}') WHERE hostid = ${idHostZabbix};"
  psql -h"${zbxHostname}" -p5432 -d"${zbxDatabase}" -U"${zbxUser}" -w -c "UPDATE interface SET ip='"${ipLocal}"' WHERE hostid=${idHostZabbix} AND type=1;"

  psql -h"${zbxHostname}" -p5432 -d"${zbxDatabase}" -U"${zbxUser}" -w -c "GRANT pg_monitor TO zbx_monitor ;" 

functionBanner "Zabbix installed with timescaledb and nginx" \
                "" \
               "Access the IP of this server in the browser with http" \
               "" \
               "http://${ipLocal}/" \
               "Default Username .: Admin" \
               "Default Password .: zabbix" \
               "" \
               "Don't forget to change the password after the first login!" \
               "" \
               "Thanks for using this script!"
bash
