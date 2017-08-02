#!/bin/bash

rm $0

# import heading function
wget -qN https://github.com/rern/title_script/raw/master/title.sh; . title.sh; rm title.sh
timestart l

# reboot command and motd
gitpath=https://github.com/rern/RuneAudio/raw/master
[[ ! -e /etc/profile.d/cmd.sh ]] && wget -qN --show-progress $gitpath/_settings/cmd.sh -P /etc/profile.d
wget -qN --show-progress $gitpath/motd/install.sh; chmod +x install.sh; ./install.sh
touch /root/.hushlogin

# passwords
echo -e "$bar root password for Samba and Transmission ...\n"
setpwd

echo -e "$bar Disable WiFi ..."
#################################################################################
systemctl disable netctl-auto@wlan0
systemctl stop netctl-auto@wlan0 shairport udevil upmpdcli
echo

echo -e "$bar Set HDMI mode ..."
#################################################################################
# prevent noobs cec hdmi power on
mkdir -p /tmp/p1
mount /dev/mmcblk0p1 /tmp/p1
if [[ -e /tmp/p1/config.txt ]]; then
  ! grep 'hdmi_ignore_cec_init=1' /tmp/p1/config.txt &> /dev/null && echo 'hdmi_ignore_cec_init=1' >> /tmp/p1/config.txt
else
  echo 'hdmi_ignore_cec_init=1' > /tmp/p1/config.txt
fi
# force hdmi mode, remove black border
if ! grep 'hdmi_mode=' /boot/config.txt &> /dev/null; then
wget -q --show-progress $gitpath/_settings/edid.dat -P /boot
echo '
hdmi_edid_file=1  # read monitor data from file (fix power off > on - wrong resolution)
hdmi_ignore_cec=1 # disable cec
hdmi_group=1
hdmi_mode=31      # 1080p 50Hz
disable_overscan=1
' >> /boot/config.txt
fi
# remove 'forcetrigger'
sed -i "s/ forcetrigger//" /tmp/p1/recovery.cmdline

### osmc ######################################
mkdir -p /tmp/p6
mount /dev/mmcblk0p6 /tmp/p6
if ! grep 'hdmi_mode=' /tmp/p6/config.txt &> /dev/null; then
echo '
hdmi_ignore_cec=1
hdmi_group=1
hdmi_mode=31
' >> /tmp/p6/config.txt
fi
sed -i '/^gpio/ s/^/#/
' /tmp/p6/config.txt
echo

echo -e "$bar Mount USB drive to /mnt/hdd ..."
#################################################################################
# disable auto update mpd database
systemctl stop mpd
sed -i '\|sendMpdCommand| s|^|//|' /srv/http/command/usbmount
sed -i '/^KERNEL/ s/^/#/' /etc/udev/rules.d/rune_usb-stor.rules
udevadm control --reload-rules && udevadm trigger

mnt0=$( mount | grep '/dev/sda1' | awk '{ print $3 }' )
label=${mnt0##/*/}
mnt="/mnt/$label"
mkdir -p "$mnt"
fstabmnt="/dev/sda1       $mnt         ext4  defaults,noatime"
if ! grep $mnt /etc/fstab &> /dev/null; then
  echo "$fstabmnt" >> /etc/fstab
  umount -l /dev/sda1
  mount -a
fi
[[ -e /mnt/MPD/USB/hdd && $( ls -1 /mnt/MPD/USB/hdd | wc -l ) == 0 ]] && rm -r /mnt/MPD/USB/hdd
ln -s $mnt/Music /mnt/MPD/USB/Music

### osmc ######################################
if ! grep $mnt /tmp/p7/etc/fstab &> /dev/null; then
  mkdir -p /tmp/p7
  mount /dev/mmcblk0p7 /tmp/p7
  echo "$fstabmnt" >> /tmp/p7/etc/fstab
  echo "$fstabmnt (+OSMC)"
fi
echo

echo -e "$bar Set pacman cache ..."
#################################################################################
echo "$mnt/varcache/pacman (+OSMC - $mnt/varcache/apt)"
mkdir -p $mnt/varcache/pacman
rm -r /var/cache/pacman
ln -s $mnt/varcache/pacman /var/cache/pacman

### osmc ######################################
if [[ ! -L /tmp/p7/var/cache/apt ]]; then
	mkdir -p $mnt/varcache/apt
	rm -r /tmp/p7/var/cache/apt
	ln -s $mnt/varcache/apt /tmp/p7/var/cache/apt
fi
# disable setup marker files
touch /tmp/p7/walkthrough_completed # initial setup
rm -f /tmp/p7/vendor # noobs marker for update prompt
echo

echo -e "$bar Restore settings ..."
#################################################################################
systemctl stop redis
file=/var/lib/redis/rune.rdb
mv $file{,.original}
wget -q --show-progress $gitpath/_settings/rune.rdb -P /var/lib/redis/
chown redis:redis $file
chmod 644 $file
systemctl restart redis

file=/var/lib/mpd/mpd.db
mv $file{,.original}
wget -q --show-progress $gitpath/_settings/mpd.db -P /var/lib/mpd
chown mpd:audio $file
chmod 644 $file
systemctl restart mpd

sed -i 's/8000/1000/' /srv/http/assets/js/runeui.js # change pnotify 8 to 1 sec
echo

# rankmirrors
wget -qN --show-progress $gitpath/rankmirrors/rankmirrors.sh; chmod +x rankmirrors.sh; ./rankmirrors.sh

echo -e "$bar Update package database ..."
#################################################################################
pacman -Sy
echo

title -l = "$bar Upgrade Samba ..."
#################################################################################
timestart
pacman -R --noconfirm samba4-rune
pacman -S --noconfirm tdb tevent smbclient samba
# fix missing libreplace-samba4.so (may need to run twice)
pacman -S --noconfirm libwbclient

# fix 'minimum rlimit_max'
echo -n '
root    soft    nofile    16384
root    hard    nofile    16384
' >> /etc/security/limits.conf

wget -q --show-progress $gitpath/_settings/smb.conf -O /etc/samba/smb-dev.conf
ln -sf /etc/samba/smb-dev.conf /etc/samba/smb.conf

# set samba password
(echo $pwd1; echo $pwd1) | smbpasswd -s -a root

timestop
title -l = "$bar Samba upgraded successfully."
echo

# Transmission
#################################################################################
wget -qN --show-progress https://github.com/rern/RuneAudio/raw/master/transmission/install.sh; chmod +x install.sh; ./install.sh $pwd1 1 1
echo

# Aria2
#################################################################################
wget -qN --show-progress https://github.com/rern/RuneAudio/raw/master/aria2/install.sh; chmod +x install.sh; ./install.sh 1
echo

# Enhancement
#################################################################################
wget -qN --show-progress https://github.com/rern/RuneUI_enhancement/raw/master/install.sh; chmod +x install.sh; ./install.sh 3
echo

# GPIO
#################################################################################
wget -qN --show-progress $gitpath/_settings/mpd.conf.gpio -P /etc
wget -qN --show-progress $gitpath/_settings/gpio.json -P /srv/http
wget -qN --show-progress https://github.com/rern/RuneUI_GPIO/raw/master/install.sh; chmod +x install.sh; ./install.sh 1
echo

curl '127.0.0.1/clear' &> /dev/null

# systemctl daemon-reload # done in GPIO install
systemctl restart nmbd smbd

# show installed packages status
echo -e "$bar Installed packages status"
systemctl | egrep 'aria2|nmbd|smbd|transmission'

# update library
#echo -e "$bar MPD library updating ..."
#mpc update &> /dev/null

timestop l
title -l = "$bar Setup finished successfully."
