echo "Removing the unused kernel that was installed by Centos"
echo "Please ignore the warnings about missing files"
yum -y erase kernel-4.11.0-22.el7a
echo "Installing ntp ..."
yum -y install ntp ntpdate
systemctl enable ntpd --now

echo "Setup a new root password"
passwd root
