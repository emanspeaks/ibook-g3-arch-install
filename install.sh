#!/bin/bash

read -sp "Enter root password: " ROOT_PASSWORD
echo

# block size is 512 bytes, total blocks is 78140160
# start block for root partition is block 57408 = 64 + 28*1024*2
# start block for swap partition is block 71360576 = 57408 + 71303168
# swap size is 6779584 [blocks] = 78140160 - 71360576
mac-fdisk /dev/sda <<EOF
i
y

C
64
28M
bootstrap
Apple_Bootstrap
c
57408
34G
root
c
71360576
6779584
swap
w
y
p
q
EOF
hformat /dev/sda2
mkfs.ext4 /dev/sda3
mkswap /dev/sda4
swapon /dev/sda4
sync
sync
sync
echo
echo "Disk setup complete. Continuing with installation in 10 seconds..."
sleep 10  # to ensure i can see any errors in disk setup before proceeding

timedatectl
mount /dev/sda3 /mnt
pacstrap /mnt/ \
  base \
  linux \
  linux-firmware \
  vim \
  grub \
  hfsutils \
  openssh \
  git \
  mesa \
  xf86-video-amdgpu \
  vulkan-radeon \
  wpa_supplicant \
  man-db \
  man-pages \
  texinfo \
  btop \
  hyfetch \
  tmux

mkdir /mnt/boot/grub
mount /dev/sda2 /mnt/boot/grub
genfstab -U /mnt > /mnt/etc/fstab

IFACE=$(ip -o link show | awk -F': ' '$2 != "lo" {print $2; exit}')
MAC=$(cat /sys/class/net/$IFACE/address)
cat > /etc/systemd/network/10-${IFACE}.link << EOF
[Match]
PermanentMACAddress=$MAC

[Link]
Name=eth0
EOF

cat > /etc/ssh/sshd_config.d/root.conf << EOF
PermitRootLogin yes
PasswordAuthentication yes
EOF

arch-chroot /mnt <<EOF
grub-mkconfig -o /boot/grub/grub.cfg
grub-install
ln -sf /usr/share/zoneinfo/America/Chicago /etc/localtime
hwclock --systohc
echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
echo "orion" > /etc/hostname
echo "$ROOT_PASSWORD" | passwd --stdin root
ln -s /usr/lib/systemd/network/80-wifi-station.network.example /etc/systemd/network/80-wifi-station.network
ln -s /usr/lib/systemd/network/89-ethernet.network.example /etc/systemd/network/89-ethernet.network
systemctl enable sshd
systemctl enable systemd-resolved
systemctl enable systemd-networkd
systemctl enable systemd-timesyncd
EOF
umount -R /mnt
hmount /dev/sda2
hattrib -t tbxi :grub
hattrib -b :
humount
reboot
