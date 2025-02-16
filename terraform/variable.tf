variable "mykey" {
  default = "Meliskey"  # SSH Key Pair
}

variable "instancetype" {
  default = "t3a.medium"  # Makine tipi
}

variable "tag" {
  default = "K3s-Server"  # EC2 etiketi
}

variable "jenkins_sg" {
  default = "jenkins-sec-gr"  # Security Group adı
}

variable "user" {
  default = "K3sUser"  # Kullanıcı tanımlaması
}
