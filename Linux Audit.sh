date;
echo "uptime"
uptime
echo "Currently Connected"
w
echo "Last Logins:"
last -a | head -3
echo "Utilization and most expensive process"
top -b | head -3
echo
top -b | head -10 | tail -4
echo "open TCP ports: "
nmap -p- -T4 127.0.0.1
echo "Current Connections:"
ss -s
echo "processes:"
ps auxf --width=200
echo "Process Which are Currently waiting for incoming processes"
netstat -tuln
echo "Checking for Kernel Update"
sudo apt update
echo  "Kernel Upgrade"
sudo apt upgrade
echo "Checking for outdated software..."
if [ -x "$(command -v apt-get)" ]; then
  sudo apt-get update
  sudo apt-get --dry-run upgrade | grep -E '^Inst' | grep -Ei 'security|fixes'
elif [ -x "$(command -v yum)" ]; then
  sudo yum check-update --security
else
  echo "Package manager not found."
fi
echo "Checking for rootkits..."
sudo chkrootkit
echo
echo "Weak Passwords:"
sudo awk -F: '($3<1000){print $1}' /etc/passwd | while read user; do
  if [ $(sudo grep -c "$user" /etc/shadow) -eq 1 ]; then
    password=$(sudo grep "$user" /etc/shadow | cut -d: -f2)
    if [ "$password" = "!" ] || [ "$password" = "*" ]; then
      echo "User $user has a weak password!"
    fi
  fi
done
echo 
echo

echo "Server hardening"
services=("rpcbind")
for service in "${services[@]}"
do
    systemctl stop $service
    systemctl disable $service
done
apt-get install -y ufw
ufw enable
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw allow http
ufw allow https

apt-get install -y libpam-pwquality
sed -i 's/password        requisite                       pam_pwquality.so.*/password        requisite                       pam_pwquality.so try_first_pass retry=3/' /etc/pam.d/common-password
sed -i 's/password        sufficient                       pam_unix.so obscure sha512/password        sufficient                       pam_unix.so obscure sha512 minlen=12/' /etc/pam.d/common-password

sed -i 's/PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config

sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config

apt-get install -y fail2ban
systemctl enable fail2ban
systemctl start fail2ban

apt-get install -y unattended-upgrades
dpkg-reconfigure -plow unattended-upgrades

apt-get install -y auditd
systemctl enable auditd
systemctl start auditd

cat <<EOT >> /etc/logrotate.d/custom_logs
/var/log/custom_log {
    weekly
    rotate 12
    compress
    delaycompress
    missingok
    notifempty
}
EOT

chmod go-rwx /etc/shadow
chmod go-rwx /etc/gshadow

echo "fs.suid_dumpable = 0" >> /etc/sysctl.conf
sysctl -p

apt-get install -y selinux-basics selinux-policy-default
selinux-activate

# Reboot the system to apply changes
#reboot

sudo apt install lynis
lynis audit system
