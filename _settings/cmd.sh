#!/bin/bash

alias ls='ls -a --color --group-directories-first'
export LS_COLORS='tw=01;34:ow=01;34:ex=00;32:or=31'

tcolor() { 
	echo -e "\e[38;5;10m$1\e[0m"
}

sstt() {
	echo -e '\n'$( tcolor "systemctl status $1" )'\n'
	systemctl status $1
}
ssta() {
	echo -e '\n'$( tcolor "systemctl start $1" )'\n'
	systemctl start $1
}
ssto() {
	echo -e '\n'$( tcolor "systemctl stop $1" )'\n'
	systemctl stop $1
}
sres() {
	echo -e '\n'$( tcolor "systemctl restart $1" )'\n'
	systemctl restart $1
}
srel() {
	echo -e '\n'$( tcolor "systemctl reload $1" )
	systemctl reload $1
}
sdre() {
	echo -e '\n'$( tcolor "systemctl daemon-reload" )'\n'
	systemctl daemon-reload
}
sfpm() {
	echo -e '\n'$( tcolor "systemctl reload php-fpm" )'\n'
	systemctl reload php-fpm
}

mmc() {
	[[ $2 ]] && mntdir=/tmp/$2 || mntdir=/tmp/p$1
	if ! mount | grep "$mntdir "; then
		mkdir -p $mntdir
		mount /dev/mmcblk0p$1 $mntdir
	fi
}

boot() {
	mmc 5
	part=$( sed -n '/name/,/mmcblk/ p' /tmp/p5/installed_os.json | sed '/part/ d; s/\s//g; s/"//g; s/,//; s/name://; s/\/dev\/mmcblk0p//' )
	partarray=( $( echo $part ) )

	ilength=${#partarray[*]}
	bootarray=(0)
	
	echo -e "\n\e[30m\e[43m ? \e[0m Reboot to OS:"
	echo -e '  \e[36m0\e[m Cancel'
	for (( i=0; i < ilength; i++ )); do
		if (( $(( i % 2 )) == 0 )); then
			echo -e "  \e[36m$(( i / 2 + 1 ))\e[m ${partarray[i]}"
		else
			bootarray+=(${partarray[i]})
		fi
	done
	echo
	list=$( seq $(( ${#bootarray[*]} - 1 )) )
	list=$( echo $list )
	echo -e "\e[36m0\e[m / ${list// / \/ } ? "
	read -n 1 ans
	echo
	[[ -z $ans || $ans == 0 ]] && return
	
	partboot=${bootarray[$ans]}
 	if [[ -e /root/reboot.py ]]; then
	 	/root/reboot.py $partboot
		exit
	fi
	
 	echo $partboot > /sys/module/bcm2709/parameters/reboot_part
 	/var/www/command/rune_shutdown 2> /dev/null; reboot
}

if [[ -d /home/osmc ]]; then
	pkgcache() {
		mnt=$( mount | grep '/dev/sda1' | awk '{ print $3 }' )
		mkdir -p $mnt/varcache/apt
		rm -rf /var/cache/apt
		ln -sf $mnt/varcache/apt /var/cache/apt
	}
	setup() {
		if [[ -e /usr/local/bin/uninstall_motd.sh ]]; then
			echo -e "\n\e[30m\e[43m ! \e[0m Already setup."
		else
			wget -qN --show-progress https://github.com/rern/OSMC/raw/master/_settings/setup.sh
			chmod +x setup.sh
			./setup.sh
		fi
	}
else
	pkgcache() {
		mnt=$( mount | grep '/dev/sda1' | awk '{ print $3 }' )
		mkdir -p $mnt/varcache/pacman/pkg
		sed -i "s|^#CacheDir.*|CacheDir    = $mnt/varcache/pacman/pkg/|" /etc/pacman.conf
	}
	setup() {
		if [[ -e /usr/local/bin/uninstall_addo.sh ]]; then
			echo -e "\e[30m\e[43m ! \e[0m Already setup."
		else
			wget -qN --show-progress https://github.com/rern/RuneAudio/raw/master/_settings/setup.sh
			if [[ $? == 5 ]]; then
				echo -e "\e[38;5;6m\e[48;5;6m . \e[0m Sync time ..."
				systemctl stop ntpd
				ntpdate pool.ntp.org
				systemctl start ntpd
				wget -qN --show-progress https://github.com/rern/RuneAudio/raw/master/_settings/setup.sh
			fi
			chmod +x setup.sh
			./setup.sh
		fi
	}
fi
