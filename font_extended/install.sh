#!/bin/bash

# required variables
alias=font
title='Fonts - Extended Characters'

# import heading function
wget -qN https://github.com/rern/title_script/raw/master/title.sh; . title.sh; rm title.sh

installstart $1

wgetnc https://github.com/rern/RuneAudio/raw/master/font_extended/uninstall_font.sh -P /usr/local/bin
chmod +x /usr/local/bin/uninstall_font.sh
wgetnc https://github.com/rern/_assets/raw/master/RuneUI_enhancement/lato.tar.xz
mv /srv/http/assets/fonts/lato{,.backup}
mkdir /srv/http/assets/fonts/lato
bsdtar -xvf lato.tar.xz -C /srv/http/assets/fonts/lato
rm lato.tar.xz

installfinish $1

title -nt "$info Refresh browser for new fonts."

[[ -t 1 ]] && clearcache
