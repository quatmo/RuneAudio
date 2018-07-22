#!/bin/bash

. /srv/http/addonstitle.sh

# get dac's output_device
ao=$( redis-cli get ao )
if [[ ${ao:0:-2} == 'bcm2835 ALSA' ]]; then
	# activate improved onboard dac (3.5mm jack) audio driver
	if ! grep 'audio_pwm_mode=2' /boot/config.txt; then
    	sed -i '$ a\audio_pwm_mode=2' /boot/config.txt
	fi
	string=$( cat <<'EOF'
	output_device=0;
	mixer_control_name = "PCM";
EOF
)
else
	output_device=$( aplay -l | grep "$ao" | sed 's/card \(.\):.*/\1/' )
	# get dac's output_format
	echo -e "$bar Get DAC Sample Format ..."
	for format in U8 S8 S16 S24 S24_3LE S24_3BE S32; do
		std=$( cat /dev/urandom | timeout 1 aplay -q -f $format 2>&1 )
		[[ -z $std ]] && output_format=$format
	done
	echo "Sample format = $output_format"
	string=$( cat <<EOF
	output_device = "hw:$output_device";
	output_format = "$output_format";
EOF
)
fi
# set config
sed -i -e "/output_device = / i\
$string
" -i '/name = "%H"/ i\
    volume_range_db = 50;
' -e '/enabled = "no"/ i\
    enabled = "yes";\
    include_cover_art = "yes";\
    pipe_name = "/tmp/shairport-sync-metadata";\
    pipe_timeout = 5000;
' -e '/run_this_before_play_begins/ i\
    run_this_before_play_begins = '/srv/http/shairport-sync.php on';\
    run_this_after_play_ends = '/srv/http/shairport-sync.php off';\
    session_timeout = 120;
' /etc/shairport-sync.conf

systemctl restart shairport-sync

title -l '=' "$info AirPlay output changed to $ao"
