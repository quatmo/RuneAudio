#!/bin/bash

alias=motd

[[ ! -e /srv/http/title.sh ]] && wget -q https://github.com/rern/RuneAudio_Addons/raw/master/title.sh -P /srv/http

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
