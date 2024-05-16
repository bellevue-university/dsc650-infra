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
sudo usermod -aG docker $USER

#Configure Kafka

KAFKA_DIR=bellevue-bigdata/kafka
EXTERNALIP=`hostname -f`
sed -i "s|IPADDR|${EXTERNALIP}|g" $KAFKA_DIR/docker-compose.yml

# Install NiFi
sudo apt-get install -y openjdk-11-jdk wget unzip jq

CURRENT_DIR=$(pwd)
NIFI_DIR="${CURRENT_DIR}/bellevue-bigdata/nifi"
mkdir -p $NIFI_DIR

# Set the specific NiFi version
NIFI_VERSION="1.25.0"
DOWNLOAD_URL="https://archive.apache.org/dist/nifi/${NIFI_VERSION}/nifi-${NIFI_VERSION}-bin.zip"

EXPECTED_FILE="${NIFI_DIR}/nifi-${NIFI_VERSION}-bin.zip"

MAX_RETRIES=10
RETRY_DELAY=10
RETRIES=0

while [[ ! -f "$EXPECTED_FILE" && $RETRIES -lt $MAX_RETRIES ]]; do
    wget -P $NIFI_DIR $DOWNLOAD_URL
    let RETRIES=RETRIES+1
    if [[ ! -f "$EXPECTED_FILE" && $RETRIES -lt $MAX_RETRIES ]]; then
        echo "Download failed, retrying in $RETRY_DELAY seconds..."
        sleep $RETRY_DELAY
    fi
done

if [[ -f "$EXPECTED_FILE" ]]; then
    unzip "$EXPECTED_FILE" -d $NIFI_DIR
    rm -rf "$EXPECTED_FILE"
else
    echo "Failed to download after $MAX_RETRIES attempts."
fi

cd ${CURRENT_DIR}

NIFI_HADOOP_CONF_DIR=bellevue-bigdata/nifi/hadoopconf
EXTERNALIP=`hostname -f`
sed -i "s|HOST|${EXTERNALIP}|g" $NIFI_HADOOP_CONF_DIR/*.xml

chmod -R 777 ${NIFI_HADOOP_CONF_DIR}

# Get the original user who ran the script with sudo
ORIGINAL_USER=${SUDO_USER:-$(whoami)}

# Add the original user to the docker group
sudo usermod -aG docker $ORIGINAL_USER

set +x

# Refresh group membership (for the current session)
sudo -u $ORIGINAL_USER newgrp docker


