#!/usr/bin/env bash
set -euo pipefail

# ROOT CHECK
if [[ $EUID -ne 0 ]]; then
  echo "Please run as root"
  exit 1
fi

# VARIABLES
AZURE_WORKSPACE_ID="${AZURE_WORKSPACE_ID:-}"
AZURE_WORKSPACE_KEY="${AZURE_WORKSPACE_KEY:-}"

### 1. CREATE USER ###
if ! id -u chaithu > /dev/null 2>&1; then
  adduser --disabled-password --gecos "" chaithu
fi
usermod -aG sudo chaithu
cat > /etc/sudoers.d/99_chaithu <<EOF
chaithu ALL=(ALL) NOPASSWD:ALL
EOF
chmod 440 /etc/sudoers.d/99_chaithu

### 2. SYSTEM UPDATE & CORE TOOLS ###
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get upgrade -y
apt-get install -y \
  apt-transport-https ca-certificates curl gnupg lsb-release software-properties-common \
  chrony unzip unattended-upgrades fail2ban ufw auditd logwatch git zsh neovim fonts-powerline

### 3. TIME SYNC ###
timedatectl set-ntp true
systemctl enable chrony
systemctl restart chrony

### 4. UNATTENDED UPGRADES ###
cat > /etc/apt/apt.conf.d/20auto-upgrades <<EOF
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
EOF

### 5. SSH HARDENING ###
sed -i 's/^#*PermitRootLogin .*/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/^#*PasswordAuthentication .*/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i 's/^#*ChallengeResponseAuthentication .*/ChallengeResponseAuthentication no/' /etc/ssh/sshd_config
sed -i 's/^#*UseDNS .*/UseDNS no/' /etc/ssh/sshd_config
systemctl reload sshd

### 6. FIREWALL (UFW) ###
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable

### 7. FAIL2BAN ###
cat > /etc/fail2ban/jail.local <<EOF
[sshd]
enabled = true
port    = ssh
maxretry = 5
bantime  = 3600
EOF
systemctl enable fail2ban
systemctl restart fail2ban

### 8. SYSCTL TUNING ###
cat > /etc/sysctl.d/99-production.conf <<EOF
net.ipv4.ip_forward = 0
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.rp_filter = 1
fs.file-max = 200000
vm.swappiness = 10
EOF
sysctl --system

### 9. AUDITD ###
systemctl enable auditd
systemctl restart auditd

### 10. DOCKER INSTALL ###
if ! command -v docker &> /dev/null; then
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
  add-apt-repository \
    "deb [arch=$(dpkg --print-architecture)] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) stable"
  apt-get update -y
  apt-get install -y docker-ce docker-ce-cli containerd.io
  systemctl enable docker
  usermod -aG docker chaithu || true
fi

### 11. LOGWATCH ###
sed -i 's/^MailTo = root/MailTo = root/' /etc/logwatch/conf/logwatch.conf
sed -i 's/^Detail = Low/Detail = Medium/' /etc/logwatch/conf/logwatch.conf

### 12. AWS CLOUDWATCH AGENT ###
if curl -s --connect-timeout 1 http://169.254.169.254/latest/meta-data/ &> /dev/null; then
  wget -q https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
  dpkg -i amazon-cloudwatch-agent.deb
  systemctl enable amazon-cloudwatch-agent
fi

### 13. AZURE MONITOR AGENT ###
if [[ -n "$AZURE_WORKSPACE_ID" && -n "$AZURE_WORKSPACE_KEY" ]]; then
  wget -q https://raw.githubusercontent.com/Microsoft/OMS-Agent-for-Linux/master/installer/scripts/onboard_agent.sh
  sh onboard_agent.sh -w "$AZURE_WORKSPACE_ID" -s "$AZURE_WORKSPACE_KEY"
  systemctl enable omsagent
fi

### 14. GIT, TERRAFORM, ANSIBLE ###
curl -fsSL https://apt.releases.hashicorp.com/gpg | apt-key add -
apt-add-repository "deb [arch=$(dpkg --print-architecture)] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
apt-get update -y
apt-get install -y terraform
apt-add-repository --yes --update ppa:ansible/ansible
apt-get update -y
apt-get install -y ansible

### 15. CERTIFICATE MANAGEMENT (Certbot) ###
apt-get install -y certbot

### 16. CONTAINER & IMAGE SECURITY (Trivy) ###
curl -fsSL https://aquasecurity.github.io/trivy-repo/deb/public.key | apt-key add -
add-apt-repository "deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -cs) main"
apt-get update -y
apt-get install -y trivy

### 17. ZSH & NEOVIM CONFIG ###
chsh -s "$(which zsh)" chaithu
su - chaithu -c "export RUNZSH=no; sh -c \"\$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)\" --unattended"
su - chaithu -c "git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \$HOME/.oh-my-zsh/custom/themes/powerlevel10k"
cat > /home/chaithu/.zshrc <<'EOF'
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"
plugins=(git docker terraform ansible)
source $ZSH/oh-my-zsh.sh
export EDITOR="nvim"
alias ll='ls -lah'
EOF
chown chaithu:chaithu /home/chaithu/.zshrc

mkdir -p /home/chaithu/.config/nvim
cat > /home/chaithu/.config/nvim/init.vim <<'EOF'
set number
syntax on
set tabstop=2 shiftwidth=2 expandtab
EOF
chown -R chaithu:chaithu /home/chaithu/.config

### 18. CLEANUP ###
apt-get autoremove -y
apt-get autoclean -y

echo "Bootstrap complete: production-ready for user 'chaithu'."
