#!/usr/bin/env bash
#######################################################################################################################################
# Programa .....: install_grafana.sh
# Data Criação .: 09/01/2026
# Descrição ....: Realiza a instalação automática do Grafana com backend PostgreSQL e SSL
#                 em sistemas RHEL-like (Rocky Linux / Alma Linux / Oracle Linux).
# Autor ........: Cleiton Maia
#######################################################################################################################################

#-----[ Environment Variables ]-------------------------------------------------------------------------------------------------------#
grafanaConfig="/etc/grafana/grafana.ini"
ipLocal=$(ip -br a | awk '$1!="lo" && $3 ~ /^[0-9]/ {print $3; exit}' | cut -d/ -f1)
grafanaHostname="grafana"
grafanaDomain="acme.local.lab"
grafanaPort="3000"
pgHost="$ipLocal"
pgPort="5432"
pgDatabase="db_grafana"
pgUser="ugrafanadmin"
pgPassword="EbDH16j7hYeebbTJBQj0ezdHCU6vCB"
sslPathSRC="/etc/nginx/ssl/"
sslPath="/usr/share/grafana/ssl"
sslKey="acme_local_lab.key"
sslCert="acme_local_lab.pem"

#-----[ System Function ]-------------------------------------------------------------------------------------------------------------#
functionBanner() {
  echo ""
  echo "╔════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╗"
  echo "║                                                                                                                        ║"
  printf "║$(tput bold) %-118s $(tput sgr0)║\n" "$@"
  echo "║                                                                                                                        ║"
  echo "╚════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╝"
  echo ""
}

functionCheckPackages() {
  for pkg in "$@"; do
    if ! command -v "$pkg" >/dev/null 2>&1; then
      return 1
    fi
  done
  return 0
}

#-----[ Validation's ]----------------------------------------------------------------------------------------------------------------#
if [[ ! -d "${sslPath}" ]]; then
  mkdir -p "${sslPath}"
fi

#-----[ Main Procedure ]--------------------------------------------------------------------------------------------------------------#
functionBanner "Automated Installation of Grafana" \
               "Backend: PostgreSQL + SSL" \
               "" \
               "Created: Cleiton Maia"
  sleep 3

functionBanner "Checking Required Packages"
  if ! functionCheckPackages curl wget tar; then
    dnf install -y curl wget tar
    if [[ $? -eq 0 ]]; then
      echo "      Packages required install successfully."
    fi
  fi

functionBanner "Configuring Firewall"
  firewall-cmd --add-port=${grafanaPort}/tcp --permanent
  firewall-cmd --reload
  if [[ $? -eq 0 ]]; then
    echo "      Firewall configured successfully."
  fi

functionBanner "Installing Grafana Repository"
  cat <<EOF > /etc/yum.repos.d/grafana.repo
[grafana]
name=Grafana OSS
baseurl=https://rpm.grafana.com
gpgkey=https://rpm.grafana.com/gpg.key
repo_gpgcheck=1
enabled=1
gpgcheck=1
sslverify=1
sslcacert=/etc/pki/tls/certs/ca-bundle.crt
EOF
  if [[ $? -eq 0 ]]; then
    echo "      Grafana repository configured successfully."
  fi

functionBanner "Installing Grafana"
  dnf -y install grafana
  if [[ $? -eq 0 ]]; then
    echo "      Grafana installed successfully."
  fi

functionBanner "Copying SSL Certificates"
  cp "${sslPathSRC}/${sslKey}" "${sslPath}/${sslKey}" 2>/dev/null
  cp "${sslPathSRC}/${sslCert}" "${sslPath}/${sslCert}" 2>/dev/null
  chown -R grafana:grafana "${sslPath}"
  chmod 750 "${sslPath}"
  chmod 600 "${sslPath}/${sslKey}"
  chmod 644 "${sslPath}/${sslCert}"
  if [[ $? -eq 0 ]]; then
    echo "      SSL Certificates copied successfully."
  fi

functionBanner "Configuring PostgreSQL Database for Grafana"
  # Create User and Database
  sudo -u postgres psql -c "CREATE USER ${pgUser} WITH PASSWORD '${pgPassword}' ;" 2>/dev/null
  sudo -u postgres psql -c "CREATE DATABASE ${pgDatabase} WITH OWNER = ${pgUser};" 2>/dev/null
  # Configuring pg_haba.conf to allow remote connections
  grep -q "${pgDatabase}.*${pgUser}.*${ipLocal}" /storage/postgres/data/pg_hba.conf \
    || echo -e "host\t${pgDatabase}\t${pgUser}\t${ipLocal}/32\tmd5" >> /storage/postgres/data/pg_hba.conf
  # echo -e "host\t${pgDatabase}\t\t${pgUser}\t${ipLocal}/32\tmd5" >> /storage/postgres/data/pg_hba.conf
  # Reload PostgreSQL configuration
  sudo -u postgres psql -c "SELECT pg_reload_conf();" 2>/dev/null

functionBanner "Configuring Grafana Backend (PostgreSQL)"
  cp "${grafanaConfig}" "${grafanaConfig}.bkp"
  sed -i \
    -e "s|^;protocol = http|protocol = https|" \
    -e "s|^;http_port = 3000|http_port = ${grafanaPort}|" \
    -e "s|^;domain = localhost|domain = ${grafanaDomain}|" \
    -e "s|^;root_url = .*|root_url = https://${grafanaHostname}.${grafanaDomain}:${grafanaPort}|" \
    -e "s|^;enforce_domain = false|enforce_domain = false|" \
    "${grafanaConfig}"
  sed -i \
    -e "s|^;cert_file =|cert_file = ${sslPath}/${sslCert}|" \
    -e "s|^;cert_key =|cert_key = ${sslPath}/${sslKey}|" \
    "${grafanaConfig}"

functionBanner "Validating SSL Certificate"
  openssl x509 -in "${sslPath}/${sslCert}" -noout >/dev/null 2>&1 || {
    echo "❌ Invalid SSL certificate"
    exit 1
  }

  cat <<INI >> /etc/grafana/grafana.ini

# #-----[ HTTP Configuration ]--------------------------------------------------------------------------------------------------------#
# [server]
# protocol = https
# http_port = ${grafanaPort}
# domain = ${grafanaHostname}.${grafanaDomain}
# root_url = https://${grafanaHostname}.${grafanaDomain}:${grafanaPort}
# #-----[ SSL Configuration ]---------------------------------------------------------------------------------------------------------#
# cert_file = ${sslPath}/${sslCert}
# cert_key = ${sslPath}/${sslKey}
#-----[ Database Configuration ]------------------------------------------------------------------------------------------------------#
[database]
type = postgres
host = ${pgHost}:${pgPort}
name = ${pgDatabase}
user = ${pgUser}
password = ${pgPassword}
ssl_mode = disable
INI
  if [[ $? -eq 0 ]]; then
    echo "      Grafana backend configured successfully."
  fi

functionBanner "Zabbix Plugin Installation"
  grafana-cli plugins install alexanderzobnin-zabbix-app

functionBanner "Set Permissions"
  chown grafana:grafana "${grafanaConfig}"
  if [[ $? -eq 0 ]]; then
    echo "      Permissions set successfully."
  fi

functionBanner "Starting Grafana Service"
  systemctl daemon-reload
  systemctl enable --now grafana-server
  sleep 5
  curl -sk https://${grafanaHostname}.${grafanaDomain}:${grafanaPort}/api/health | grep -q ok 
  if [[ $? -ne 0 ]]; then
    echo "❌ Grafana health-check failed"
    exit 1
  else
    echo "      Grafana service started successfully."
  fi

functionBanner "Grafana Installation Completed Successfully" \
               "" \
               "Access URL:" \
               "https://${grafanaHostname}.${grafanaDomain}:${grafanaPort}" \
               "" \
               "Default User.....: admin" \
               "Default Password.: admin" \
               "" \
               "Change the password on first login!" \
               "" \
               "Thanks for using this script!"
