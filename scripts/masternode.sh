#!/bin/bash


#start the kube master node
sudo apt update
sudo apt-get install -y apt-transport-https ca-certificates curl
sudo apt install docker.io -y
sudo systemctl enable --now docker

# Adding GPG keys.
curl -fsSL "https://packages.cloud.google.com/apt/doc/apt-key.gpg" | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/kubernetes-archive-keyring.gpg
# Add the repository to the sourcelist.
echo 'deb https://packages.cloud.google.com/apt kubernetes-xenial main' | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt update 
sudo apt install kubeadm=1.20.0-00 kubectl=1.20.0-00 kubelet=1.20.0-00 -y

#intialize the kubernetes master node
sudo su
kubeadm init

#set up local kubeconfig
mkdir -p $HOME_DIR/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME_DIR/.kube/config
sudo chown $(id -u):$(id -g) $HOME_DIR/.kube/config

#apply weave network
kubectl apply -f https://github.com/weaveworks/weave/releases/download/v2.8.1/weave-daemonset-k8s.yaml

#generate a token for worker nodes to join
sudo kubeadm token create --print-join-command 2>&1 | tee join.txt