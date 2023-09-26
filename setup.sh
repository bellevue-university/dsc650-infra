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

KAFKA_DIR=bellvue-bigdata/kafka
EXTERNALIP=`hostname -f`
sed -i "s|IPADDR|${EXTERNALIP}|g" $KAFKA_DIR/docker-compose.yml

# Install NiFi
sudo apt-get install -y openjdk-11-jdk wget unzip jq

CURRENT_DIR=`pwd`
NIFI_DIR="${CURRENT_DIR}/bellvue-bigdata/nifi"
mkdir -p $NIFI_DIR

MIRROR=$(curl -s https://www.apache.org/dyn/closer.cgi?as_json=1 | jq -r '.preferred')
NIFI_FULL_VERSION=$(curl -s https://nifi.apache.org/download.html | grep -Eo 'nifi-[0-9]+.[0-9]+.[0-9]+' | sort -V | tail -1)
NIFI_VERSION=$(echo $NIFI_FULL_VERSION | grep -oP '(?<=nifi-).+')
DOWNLOAD_URL="${MIRROR}nifi/${NIFI_VERSION}/${NIFI_FULL_VERSION}-bin.zip"

EXPECTED_FILE="${NIFI_DIR}/${NIFI_FULL_VERSION}-bin.zip"

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
    exit 1
fi

cd ${CURRENT_DIR}
set +x
newgrp docker

