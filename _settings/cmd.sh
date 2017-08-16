#!/bin/bash

alias ls='ls -a --color --group-directories-first'
export LS_COLORS='tw=01;34:ow=01;34:ex=00;32:or=31'

tcolor() { 
	echo -e "\e[38;5;10m$1\e[0m"
}

sstatus() {
	echo -e '\n'$( tcolor "systemctl status $1" )'\n'
	systemctl status $1
}
sstart() {
	echo -e '\n'$( tcolor "systemctl start $1" )'\n'
	systemctl start $1
}
sstop() {
	echo -e '\n'$( tcolor "systemctl stop $1" )'\n'
	systemctl stop $1
}
srestart() {
	echo -e '\n'$( tcolor "systemctl restart $1" )'\n'
	systemctl restart $1
}
sreload() {
	echo -e '\n'$( tcolor "systemctl stop $1" )
	systemctl stop $1
	echo -e '\n'$( tcolor "systemctl disable $1" )
	systemctl disable $1
	echo -e '\n'$( tcolor "systemctl daemon-reload" )
	systemctl daemon-reload
	echo -e '\n'$( tcolor "systemctl enable $1" )
	systemctl enable $1
	echo -e '\n'$( tcolor "systemctl start $1" )
	systemctl start $1
}

mmc() {
	[[ $2 ]] && mntdir=/tmp/$2 || mntdir=/tmp/p$1
	if [[ ! $( mount | grep $mntdir ) ]]; then
		mkdir -p $mntdir
		mount /dev/mmcblk0p$1 $mntdir
	fi
}

bootx() {
 	if [[ -e /root/reboot.py ]]; then
	 	/root/reboot.py $1
		exit
	fi
 	echo $1 > /sys/module/bcm2709/parameters/reboot_part
 	/var/www/command/rune_shutdown
 	reboot
}
bootosmc() {
 	bootx 6 &
}
bootrune() {
	bootx 8 &
}

setup() {
	if [[ ! -e /etc/motd.logo ]]; then
		wget -qN --show-progress https://raw.githubusercontent.com/rern/RuneAudio/master/_settings/setup.sh
		chmod +x setup.sh
		./setup.sh
	else
		echo -e "\e[30m\e[43m ! \e[0m Already setup."
	fi
}
resetosmc() {
	. osmcreset n
	if [[ $success != 1 ]]; then
		echo -e "\e[37m\e[41m ! \e[0m OSMC reset failed."
		return
	fi
	# preload initial setup
	wget -qN --show-progress https://raw.githubusercontent.com/rern/OSMC/master/_settings/presetup.sh
	. presetup.sh
	# preload command shortcuts
	mmc 7
	wget -qN --show-progress https://raw.githubusercontent.com/rern/OSMC/master/_settings/cmd.sh -P /tmp/p7/etc/profile.d
	
	[[ $ansre == 1 ]] && bootosmc
}

hardreset() {
	echo -e "\n\e[30m\e[43m ? \e[0m Reset to virgin OS:"
	echo -e '  \e[36m0\e[m Cancel'
	echo -e '  \e[36m1\e[m OSMC'
	echo -e '  \e[36m2\e[m NOOBS: OSMC + Rune'
	echo
	echo -e '\e[36m0\e[m / 1 / 2 ? '
	read -n 1 ans
	echo
	case $ans in
		1) resetosmc;;
		2) noobsreset;;
		*) ;;
	esac
}
