###############################################
#            k8s前置工作                        
#        1.本机相关配置初始化                    
#        2.cri安装（docker）                   
#        3.kube相关组件安装                    
#                                             
#                                             
###############################################

##################################################
# 硬件条件：cpus >= 2, mems >= 2G
# 本机配置更改

# 检查机主机名、mac及product_uuid的唯一性
# hostname
# ifconfig 
# cat /sys/class/dmi/id/product_uuid

# 内部通信需要开放很多接口，关闭防火墙
systemctl stop firewalld
systemctl disable firewalld

# 禁用selinux功能，方便容器访问宿主文件系统
setenforce 0 && sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config

# 禁用swap分区，不禁用kuberadm会报错
# 查看swap的挂载节点
swapon -s
# 关闭swap
swapon -s | grep 'partition'| awk '{print$1}' | xargs swapoff
# 修改 fstab
sed -i '/swap/s/^/#/g' /etc/fstab


# 于 iptables 被绕过而导致流量无法正确路由的问题。确保 在 sysctl 配置中的 net.bridge.bridge-nf-call-iptables 被设置为 1。
cat <<EOF >  /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sysctl --system

# reboot

##################################################
# 安装docker-ce



sudo yum install -y yum-utils device-mapper-persistent-data lvm2
sudo yum-config-manager --add-repo http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
sudo yum makecache fast
sudo yum -y install docker-ce

### 安装所需包
yum install yum-utils device-mapper-persistent-data lvm2

### 新增 Docker 仓库。
yum-config-manager \
  --add-repo \
  https://download.docker.com/linux/centos/docker-ce.repo

## 安装 Docker CE.
yum update -y && yum install -y \
  containerd.io-1.2.13 \
  docker-ce-19.03.11 \
  docker-ce-cli-19.03.11

## 创建 /etc/docker 目录。
mkdir /etc/docker

# 设置 daemon。
cat > /etc/docker/daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2",
  "storage-opts": [
    "overlay2.override_kernel_check=true"
  ]
}
EOF

mkdir -p /etc/systemd/system/docker.service.d

# 重启 Docker
systemctl daemon-reload
systemctl restart docker

sudo systemctl enable docker

##################################################
# 安装kubeadm kubectl kubelet

# k8s镜像仓库
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64
# baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
# gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF

yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes

systemctl enable --now kubelet


kubeadm reset && kubeadm init --apiserver-advertise-address 192.168.52.128 --pod-network-cidr=10.244.0.0/16 --image-repository registry.aliyuncs.com/google_containers

kubeadm token create --print-join-command