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

# Update Kafka

KAFKA_DIR=bellvue-bigdata/kafka
EXTERNALIP=`hostname -f`
sed -i "s|IPADDR|${EXTERNALIP}|g" ${KAFKA_DIR}/docker-compose.yml

# Install NiFi
sudo apt-get install -y openjdk-11-jdk wget unzip

CURRENT_DIR=`pwd`
NIFI_DIR=bellvue-bigdata/nifi
NIFI_VERSION=1.23.0

cd ${NIFI_DIR}
echo "Installing NiFi version: $NIFI_VERSION"

# Download and extract NiFi
wget https://dlcdn.apache.org/nifi/${NIFI_VERSION}/nifi-${NIFI_VERSION}-bin.zip
unzip nifi-${NIFI_VERSION}-bin.zip

rm -rf nifi-${NIFI_VERSION}-bin.zip

cd ${CURRENT_DIR}


