#!/bin/bash

echo "Script version: 1.0.0"

read -p "Enter hostname: " NEW_HOSTNAME
echo
read -sp "Enter root password: " ROOT_PASSWORD
echo

# block size is 512 bytes, total blocks is 78140160
# start block for root partition is block 57408 = 64 + 28*1024*2
# start block for swap partition is block 71360576 = 57408 + 71303168
# swap size is 6779584 [blocks] = 78140160 - 71360576
umount /dev/sda2
umount /dev/sda3
swapoff -a
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

mkdir -p /mnt/usr/local/share/kbd/keymaps
cat > /mnt/usr/local/share/kbd/keymaps/ibook.map <<EOF
include "/usr/share/kbd/keymaps/i386/qwerty/us.map.gz"

alt keycode 65 = Console_1
control alt keycode 65 = Console_1
alt keycode 66 = Console_2
control alt keycode 66 = Console_2
alt keycode 67 = Console_3
control alt keycode 67 = Console_3
EOF
echo "KEYMAP=/usr/local/share/kbd/keymaps/ibook.map" > /mnt/etc/vconsole.conf

# remove these from the list of packages to install for now
#   linux-firmware \
#   vulkan-radeon \
#   wpa_supplicant \
pacstrap /mnt/ \
  base \
  linux \
  vim \
  grub \
  hfsutils \
  linux-firmware-amdgpu \
  linux-firmware-radeon \
  linux-headers \
  mesa \
  xf86-video-amdgpu \
  openssh \
  git \
  man-db \
  man-pages \
  texinfo \
  btop \
  hyfetch \
  tmux \
  clang \
  cmake \
  llvm \
  lld \
  which

mkdir /mnt/boot/grub
mount /dev/sda2 /mnt/boot/grub
genfstab -U /mnt > /mnt/etc/fstab

IFACE=$(ip -o link show | awk -F': ' '$2 != "lo" {print $2; exit}')
MAC=$(cat /sys/class/net/$IFACE/address)
cat > /mnt/etc/systemd/network/10-${IFACE}.link <<EOF
[Match]
PermanentMACAddress=$MAC

[Link]
Name=eth0
EOF

mkdir -p /mnt/etc/ssh/sshd_config.d
cat > /mnt/etc/ssh/sshd_config.d/root.conf <<EOF
PermitRootLogin yes
PasswordAuthentication yes
EOF

mkdir -p /mnt/root/.config
cat > /mnt/root/.config/hyfetch.json <<EOF
{
    "preset": "rainbow",
    "mode": "rgb",
    "auto_detect_light_dark": false,
    "light_dark": "dark",
    "lightness": 0.65,
    "color_align": {
        "mode": "horizontal"
    },
    "backend": "neofetch",
    "args": null,
    "distro": null,
    "pride_month_disable": false,
    "custom_ascii_path": null
}
EOF

mkdir -p /mnt/opt/zig
curl -sL https://raw.githubusercontent.com/emanspeaks/ibook-g3-arch-install/main/zig.sh -o /mnt/opt/zig/build.sh

arch-chroot /mnt <<EOF
grub-mkconfig -o /boot/grub/grub.cfg
grub-install
ln -sf /usr/share/zoneinfo/America/Chicago /etc/localtime
hwclock --systohc
echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
echo "$NEW_HOSTNAME" > /etc/hostname
echo "$ROOT_PASSWORD" | passwd --stdin root
ln -s /usr/lib/systemd/network/80-wifi-station.network.example /etc/systemd/network/80-wifi-station.network
ln -s /usr/lib/systemd/network/89-ethernet.network.example /etc/systemd/network/89-ethernet.network
systemctl enable sshd
systemctl enable systemd-resolved
systemctl enable systemd-networkd
systemctl enable systemd-timesyncd
useradd --system --shell \$(which btop) btop-monitor
EOF

mkdir -p /mnt/etc/systemd/system/getty@tty1.service.d
cat > /mnt/etc/systemd/system/getty@tty1.service.d/override.conf <<EOF
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin btop-monitor --noclear %I \$TERM
EOF

sync
sync
sync
umount -R /mnt
hmount /dev/sda2
hattrib -t tbxi :grub
hattrib -b :
humount
echo "Install complete!"
# echo "Press any key to reboot..."
# read -srn 1
# reboot
