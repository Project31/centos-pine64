#!/bin/bash

# Default value used if no argument is provided
dev=sda

cat banner.txt

if [ $# -eq 1 ]
  then
  dev=$1
fi
echo "WARNING: Proceeding will result in the loss of ALL data on device /dev/$dev !! "
read -p "Are you sure you want to proceed [y,N]? " -r
echo 
if [[ ! $REPLY =~ ^[yY]$ ]] 
  then
    echo "Leaving flash process before any harm was done"
    echo "Usage install.sh <device_name>"
    echo 
    exit 0
fi

if mount | grep /dev/${dev}1 > /dev/null; then
   echo "Removing mount to /dev/${dev}1"
   umount /dev/${dev}1
fi

armbian=Armbian_5.67_Rockpro64_Ubuntu_bionic_default_4.4.166_desktop
centos=CentOS-7-aarch64-rootfs-7.4.1708.tar.xz
micro_sd_size=7500
gitdir=`pwd`

if [ ! -f $gitdir/armbian/${armbian}.img ]; then
  cd $gitdir/armbian
  if [ ! -f $gitdir/armbian/${armbian}.7z ]; then
    wget https://github.com/Project31/centos-pine64/releases/download/Armbian_5.67_Rockpro64/${armbian}.7z
  fi
  p7zip -d ${armbian}.7z
fi
cd $gitdir

if [ ! -f $gitdir/centos/${centos} ]; then
  cd centos
  wget https://github.com/Project31/centos-pine64/releases/download/vCentos7.4.1708/$centos
fi

echo "Flashing Armbian to '$dev' ..."

dd bs=1MB if=armbian/${armbian}.img of=/dev/$dev status=progress
sync

echo Resize ${dev}1 partition
echo "resizepart 1 ${micro_sd_size}\n\q\n" | parted /dev/$dev
sync
resize2fs /dev/${dev}1
sync

echo "Mounting rootfs filesystem"
mount /dev/${dev}1 ./rootfs

echo "Saving Armbian UBoot and Kernel ..."
mkdir -p $gitdir/rootfs/armbian/lib
cp -r $gitdir/rootfs/boot $gitdir/rootfs/armbian/
cp -r $gitdir/rootfs/lib/firmware $gitdir/rootfs/armbian/lib
cp -r $gitdir/rootfs/lib/modules $gitdir/rootfs/armbian/lib

cd $gitdir/rootfs

shopt -s extglob
rm -fr !("armbian")

echo "Extracting CentOS-7-aarch64-rootfs-7.4.1708..."
tar --numeric-owner -xpf $gitdir/centos/CentOS-7-aarch64-rootfs-7.4.1708.tar.xz

echo "Replacing CentOS kernel artifacts with Armbian"
rm -fr ./boot ./lib/modules ./lib/firmware
mv $gitdir/rootfs/armbian/boot .
mv $gitdir/rootfs/armbian/lib/modules $gitdir/rootfs/lib/
mv $gitdir/rootfs/armbian/lib/firmware $gitdir/rootfs/lib
rm -fr $gitdir/rootfs/armbian

echo "Adding /etc/fstab"
echo "UUID=b00195c2-0737-43f7-a1f3-597a48e6343a / ext4 defaults 0 0" > $gitdir/rootfs/etc/fstab

cp $gitdir/finish-centos-install.sh $gitdir/rootfs/root/

sync
umount $gitdir/rootfs

echo "Flashing complete!"
echo "Please boot from the microSD card, login using root/centos and run 'sh /root/finish-centos-install.sh' to complete the installation"
