#!/bin/bash

alias=motd

wget -qN https://github.com/rern/RuneAudio_Addons/raw/master/title.sh; . title.sh; rm title.sh
[[ ! -e /srv/http/addonslist.php ]] && wgetnc https://github.com/rern/RuneAudio_Addons/raw/master/srv/http/addonslist.php -P /srv/http

uninstallstart $1

echo -e "$bar Restore files ..."

mv -v /etc/motd{.original,}
rm -v /etc/motd.logo /etc/profile.d/motd.sh

file=/etc/bash.bashrc
echo $file
sed -i -e '/^PS1=/ d
' -e '/^#PS1=/ s/^#//
' $file

uninstallfinish $1

title -nt "$info Relogin to see original motd."
