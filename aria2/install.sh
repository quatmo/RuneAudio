#!/bin/bash

# change version number in RuneAudio_Addons/srv/http/addonslist.php

alias=aria

. /srv/http/addonstitle.sh

installstart $1

getuninstall

gitpath=https://github.com/rern/RuneAudio/raw/master

rankmirrors

echo -e "$bar Aria2 package ..."
pacman -Sy --noconfirm aria2 glibc

if mount | grep -q '/dev/sda1'; then
	mnt=$( mount | grep '/dev/sda1' | awk '{ print $3 }' )
	mkdir -p $mnt/aria2
	path=$mnt/aria2
else
	mkdir -p /root/aria2
	path=/root/aria2
fi

echo -e "$bar WebUI ..."
wgetnc https://github.com/ziahamza/webui-aria2/archive/master.zip
rm -rf $path/web
mkdir $path/web
bsdtar -xf master.zip --strip 1 -C $path/web
rm master.zip

ln -s $path/web /srv/http/aria2

# modify file
file=/etc/nginx/nginx.conf
echo $file
if ! grep -q 'aria2' $file; then
	linenum=$( sed -n '/listen 80 /=' $file )

sed -i -e '/^\s*rewrite/ s/^\s*/&#/
' -e "$(( $linenum + 7 ))"' a\
\            rewrite /css/(.*) /assets/css/$1 break;\
\            rewrite /less/(.*) /assets/less/$1 break;\
\            rewrite /js/(.*) /assets/js/$1 break;\
\            rewrite /img/(.*) /assets/img/$1 break;\
\            rewrite /fonts/(.*) /assets/fonts/$1 break;
' -e "$(( $linenum + 9 ))"' a\
\        location /aria2 {\
\            alias '$path'/web;\
\        }\
' $file
fi

mkdir -p /root/.config/aria2
file=/root/.config/aria2/aria2.conf
echo $file
echo "enable-rpc=true
rpc-listen-all=true
daemon=true
disable-ipv6=true
dir=$path
max-connection-per-server=4
" > $file

file=/etc/systemd/system/aria2.service
echo $file
echo '[Unit]
Description=Aria2
After=network-online.target
[Service]
Type=forking
ExecStart=/usr/bin/aria2c
[Install]
WantedBy=multi-user.target
' > $file

[[ $1 == 1 ]] || [[ $( redis-cli get ariastartup ) ]] && systemctl enable aria2
redis-cli del ariastartup &> /dev/null

echo -e "$bar Start $title ..."
if ! systemctl start aria2 &> /dev/null; then
	title -l = "$warn $title install failed."
	exit
fi

installfinish $1

echo "Run: systemctl < start / stop > aria2"
echo "Startup: systemctl < enable / disable > aria2"
echo
echo "Download directory: $path"
title -nt "WebUI: < RuneAudio_IP >/aria2/"

# refresh svg support last for directories fix
systemctl reload nginx
