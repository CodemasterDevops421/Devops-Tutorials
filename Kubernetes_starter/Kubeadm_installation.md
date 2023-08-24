# Kubeadm Installation Guide

This guide outlines the steps to set up a Kubernetes cluster using kubeadm on Ubuntu (Xenial or later) with sudo privileges, internet access, and a t2.medium instance type or higher.

## Pre-requisites
* Ubuntu OS (Xenial or later)
* sudo privileges
* Internet access
* t2.medium instance type or higher

## Both Master & Worker Node

Prepare both the master and worker nodes by running the following commands:

\`\`\`bash
sudo su
apt update -y
apt install docker.io -y

systemctl start docker
systemctl enable docker

curl -fsSL "https://packages.cloud.google.com/apt/doc/apt-key.gpg" | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/kubernetes-archive-keyring.gpg
echo 'deb https://packages.cloud.google.com/apt kubernetes-xenial main' > /etc/apt/sources.list.d/kubernetes.list

apt update -y
apt install kubeadm=1.20.0-00 kubectl=1.20.0-00 kubelet=1.20.0-00 -y
\`\`\`

## Master Node

1. **Initialize the Master Node:**
   \`\`\`bash
   sudo su
   kubeadm init
   \`\`\`

2. **Set up Local Kubeconfig:**
   \`\`\`bash
   mkdir -p $HOME/.kube
   sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
   sudo chown $(id -u):$(id -g) $HOME/.kube/config
   \`\`\`

3. **Apply Weave Network:**
   \`\`\`bash
   kubectl apply -f https://github.com/weaveworks/weave/releases/download/v2.8.1/weave-daemonset-k8s.yaml
   \`\`\`

4. **Generate Token for Worker Nodes:**
   \`\`\`bash
   kubeadm token create --print-join-command
   \`\`\`

5. **Expose Port 6443** in the Security group for the Worker to connect to Master Node.

## Worker Node

1. **Prepare Worker Node:**
   \`\`\`bash
   sudo su
   kubeadm reset pre-flight checks
   \`\`\`

2. **Join the Worker Node:** Paste the join command you got from the master node and append \`--v=5\` at the end.

## Verify Cluster Connection

Verify the connection to the cluster on the Master Node:

\`\`\`bash
kubectl get nodes
\`\`\`

## Optional Steps

* **Labeling Nodes:**
  \`\`\`bash
  kubectl label node <node-name> node-role.kubernetes.io/worker=worker
  \`\`\`

* **Test a Demo Pod:**
  \`\`\`bash
  kubectl run hello-world-pod --image=nginx --restart=Never --command -- sh -c "echo 'Hello, World' && sleep 3600"
  \`\`\`

---

