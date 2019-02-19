#!/bin/bash

rm $0

. /srv/http/addonstitle.sh

title -l '=' "$bar Update / Create coverarts for browsing ..."
timestart

albums=$( mpc stats | grep Albums | awk '{ print $NF }' )
minutes=(( $album / 5 ))
echo -e "$bar This may take up to $minutes minutes ..."

wgetnc https://github.com/rern/RuneAudio/raw/master/coverarts/enhancecoverart.php
chmod +x enhancecoverart.php
./enhancecoverart.php

timestop

title "$bar Update / Create coverarts completed."
