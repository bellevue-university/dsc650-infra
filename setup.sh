#!/bin/bash

set -x

# Install Docker
sudo apt-get -y update
sudo apt-get -y install ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings
[ -e /etc/apt/keyrings/docker.gpg ] && sudo rm /etc/apt/keyrings/docker.gpg
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get -y update
sudo apt-get -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo systemctl start docker.service
sudo systemctl enable docker.service
sudo apt-get -y install docker-compose
# Fix for Python 3.12 distutils removal – re-enable docker-compose v1
sudo apt install -y python3-pip
sudo pip install --break-system-packages setuptools==68.2.2
sudo usermod -aG docker $USER

# Configure Kafka
KAFKA_DIR=bellevue-bigdata/kafka
EXTERNALIP=$(hostname -f)
sed -i "s|IPADDR|${EXTERNALIP}|g" "$KAFKA_DIR/docker-compose.yml"

# Install NiFi prerequisites
sudo apt-get install -y openjdk-11-jdk wget unzip jq aria2

CURRENT_DIR=$(pwd)
NIFI_DIR="${CURRENT_DIR}/bellevue-bigdata/nifi"
mkdir -p "$NIFI_DIR"

# --- Fast NiFi 1.25.0 download (ZIP from archive, parallel + resume + size check) ---
NIFI_VERSION="1.25.0"
NIFI_BASE="nifi-${NIFI_VERSION}"
NIFI_ZIP="${NIFI_BASE}-bin.zip"
ARCHIVE_URL="https://archive.apache.org/dist/nifi/${NIFI_VERSION}/${NIFI_ZIP}"
EXPECTED_FILE="${NIFI_DIR}/${NIFI_ZIP}"
MIN_BYTES=$((100 * 1024 * 1024))   # sanity: must be >100MB

fetch_file() {
  local url="$1" out="$2"
  aria2c -x16 -s16 -k1M -d "$(dirname "$out")" -o "$(basename "$out")" "$url" && return 0
  curl -L --retry 5 --retry-delay 5 -C - -o "$out" "$url" && return 0
  wget -c -O "$out" "$url" && return 0
  return 1
}

good_size() {
  local f="$1"
  [ -f "$f" ] || return 1
  local sz
  sz=$(stat -c%s "$f" 2>/dev/null || echo 0)
  [ "$sz" -ge "$MIN_BYTES" ]
}

if fetch_file "$ARCHIVE_URL" "$EXPECTED_FILE"; then
  if good_size "$EXPECTED_FILE"; then
    unzip -q "$EXPECTED_FILE" -d "$NIFI_DIR"
    rm -f "$EXPECTED_FILE"
    echo "NiFi ${NIFI_VERSION} downloaded and extracted."
  else
    echo "Downloaded file too small — likely a 404 page. Aborting."
    rm -f "$EXPECTED_FILE"
    exit 1
  fi
else
  echo "Failed to download NiFi ${NIFI_VERSION} from archive."
  exit 1
fi

cd "${CURRENT_DIR}"

NIFI_HADOOP_CONF_DIR_ROOT=bellevue-bigdata/nifi
EXTERNALIP=$(hostname -f)
sed -i "s|HOST|${EXTERNALIP}|g" "$NIFI_HADOOP_CONF_DIR_ROOT"/hadoopconf/*.xml

chmod -R 777 "${NIFI_HADOOP_CONF_DIR_ROOT}"

# Get the original user who ran the script with sudo
ORIGINAL_USER=${SUDO_USER:-$(whoami)}

# Add the original user to the docker group
sudo usermod -aG docker "$ORIGINAL_USER"

set +x

# Refresh group membership (for the current session)
sudo -u "$ORIGINAL_USER" newgrp docker
