#!/bin/bash

# change version number in RuneAudio_Addons/srv/http/addonslist.php

alias=udac

. /srv/http/addonstitle.sh
. /srv/http/addonsedit.sh

installstart $@

getuninstall

echo -e "$bar Modify files ..."

file=/etc/udev/rules.d/rune_usb-audio.rules
echo $file
# split add-remove to suppress notify twice
commentS 'SUBSYSTEM=="sound"'

unitfile() {
    string=$( cat <<EOF
[Unit]
Description=Hotplug USB DAC
[Service]
Type=oneshot
ExecStart=/root/usbdac $1
[Install]
WantedBy=multi-user.target
EOF
)
    echo "$string" > /etc/systemd/system/$2.service
}
unitfile on usbdacon
unitfile '' usbdacoff

string=$( cat <<'EOF'
ACTION=="add", SUBSYSTEM=="sound", RUN+="/usr/bin/systemctl start usbdacon.service"
ACTION=="remove", SUBSYSTEM=="sound", RUN+="/usr/bin/systemctl start usbdacoff.service"
EOF
)
appendS 'SUBSYSTEM=="sound"'

udevadm control --reload-rules
systemctl restart systemd-udevd

file=/root/usbdac
string=$( cat <<'EOF'
#!/usr/bin/php

<?php
$redis = new Redis();
$redis->pconnect( '127.0.0.1' );
include '/srv/http/app/libs/runeaudio.php';

wrk_mpdconf( $redis, 'refresh' );

if ( $argc > 1 ) {
	// "exec" gets only last line which is new power-on card
	$ao = exec( '/usr/bin/aplay -lv | grep card | cut -d"]" -f1 | cut -d"[" -f2' );
	$name = $ao;
} else {
	$ao = $redis->get( 'aodefault' );
	$name = $redis->hGet( 'udaclist', $ao );
}

ui_notify( 'Audio Output Switch', $name );
wrk_mpdconf( $redis, 'switchao', $ao );
EOF
)
echo "$string" > $file

chmod +x $file

redis-cli set aodefault "$1" &> /dev/null

installfinish $@
