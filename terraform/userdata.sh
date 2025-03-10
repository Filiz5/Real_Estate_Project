#! /bin/bash
# Sistem Güncelleme
apt update -y && apt upgrade -y

# Hostname Ayarı
hostnamectl set-hostname k3s-server

# Gerekli Paketlerin Kurulumu
apt install -y git curl wget unzip apt-transport-https ca-certificates gnupg lsb-release software-properties-common

# AWS CLI Kurulumu
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
rm -rf awscliv2.zip aws/

# Java 17 ve Java 21 Kurulumu
apt install -y openjdk-17-jdk openjdk-21-jdk

# Varsayılan Java Sürümünü Ayarlama
update-alternatives --install /usr/bin/java java /usr/lib/jvm/java-17-openjdk-amd64/bin/java 1
update-alternatives --install /usr/bin/java java /usr/lib/jvm/java-21-openjdk-amd64/bin/java 2

# Varsayılan Java Sürümünü Kontrol Et
update-alternatives --config java


# Python, AWS SDK ve Terraform Kurulumu
apt install -y python3-pip python3-dev
pip3 install boto3 botocore
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list
apt update && apt install -y terraform

# Kubernetes CLI (kubectl) Kurulumu
curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | gpg --dearmor -o /usr/share/keyrings/kubernetes-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | tee /etc/apt/sources.list.d/kubernetes.list
apt update && apt install -y kubectl

# Kompose Kurulumu
curl -L https://github.com/kubernetes/kompose/releases/download/v1.30.0/kompose-linux-amd64 -o /usr/local/bin/kompose
chmod +x /usr/local/bin/kompose

# K3s Kurulumu (IMDSv2 uyumlu, garantili yöntem)
TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")

PUBLIC_IP=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/meta-data/public-ipv4)

curl -sfL https://get.k3s.io | sh -s - --tls-san $PUBLIC_IP

systemctl enable k3s
systemctl start k3s

# Kubeconfig Ayarı
mkdir -p /home/ubuntu/.kube
cp /etc/rancher/k3s/k3s.yaml /home/ubuntu/.kube/config
chown ubuntu:ubuntu /home/ubuntu/.kube/config
export KUBECONFIG=/home/ubuntu/.kube/config
