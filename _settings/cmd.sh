#!/bin/bash

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

bootosmc() {
	echo 6 > /sys/module/bcm2709/parameters/reboot_part
	/var/www/command/rune_shutdown
	reboot
}
bootrune() {
	echo 8 > /sys/module/bcm2709/parameters/reboot_part
	/var/www/command/rune_shutdown
	reboot
}
hardreset() {
	echo
	echo 'Reset to virgin NOOBS?'
	echo -e '  \e[0;36m0\e[m No'
	echo -e '  \e[0;36m1\e[m Yes'
	echo
	echo -e '\e[0;36m0\e[m / 1 ? '
	read -n 1 ans
	
	if [[ $ans == 1 ]]; then
		mkdir /tmp/p1
		mount /dev/mmcblk0p1 /tmp/p1
		echo -n " forcetrigger" >> /tmp/p1/recovery.cmdline
		/var/www/command/rune_shutdown
		reboot
	fi
}
