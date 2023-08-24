# Install Docker

sudo apt-get -y update
sudo apt-get -y install ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings
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
newgrp docker

# Install NiFi
sudo apt-get install -y openjdk-11-jdk wget unzip jq

CURRENT_DIR=`pwd`
NIFI_DIR=bellvue-bigdata/nifi

cd ${NIFI_DIR}

# Fetch the preferred mirror from Apache
MIRROR=$(curl -s https://www.apache.org/dyn/closer.cgi?as_json=1 | jq -r '.preferred')

# Fetch the latest NiFi version from Apache NiFi site
NIFI_FULL_VERSION=$(curl -s https://nifi.apache.org/download.html | grep -Eo 'nifi-[0-9]+.[0-9]+.[0-9]+' | sort -V | tail -1)
NIFI_VERSION=$(echo $NIFI_FULL_VERSION | grep -oP '(?<=nifi-).+')

# Construct the URL for latest NiFi tarball
DOWNLOAD_URL="${MIRROR}nifi/${NIFI_VERSION}/${NIFI_FULL_VERSION}-bin.zip"

# Download the tarball
wget $DOWNLOAD_URL

unzip nifi-*-bin.zip

rm -rf nifi-*-bin.zip

cd ${CURRENT_DIR}
