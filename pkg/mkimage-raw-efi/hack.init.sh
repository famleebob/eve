#!/bin/sh

# this is the init script version
VERSION=3.6.2-EVE
SINGLEMODE=no
sysroot=/sysroot
splashfile=/.splash.ctrl
repofile=/tmp/repositories
#KOPT_usbdelay=3
#KOPT_debug_init=yes

trap "" SIGCHLD

# some helpers
ebegin() {
	last_emsg="$*"
	echo "$last_emsg..." > /dev/kmsg
	[ "$KOPT_quiet" = yes ] && return 0
	echo -n " * $last_emsg: "
}
eend() {
	local msg
	if [ "$1" = 0 ] || [ $# -lt 1 ] ; then
		echo "$last_emsg: ok." > /dev/kmsg
		[ "$KOPT_quiet" = yes ] && return 0
		echo "ok."
	else
		shift
		echo "$last_emsg: failed. $*" > /dev/kmsg
		if [ "$KOPT_quiet" = "yes" ]; then
			echo -n "$last_emsg "
		fi
		echo "failed. $*"
		echo "initramfs emergency recovery shell launched. Type 'exit' to continue boot"
		/usr/bin/busybox sh
	fi
}

unpack_apkovl() {
	local ovl="$1"
	local dest="$2"
	local suffix=${ovl##*.}
	local i
	ovlfiles=/tmp/ovlfiles
	if [ "$suffix" = "gz" ]; then
		tar -C "$dest" -zxvf "$ovl" > $ovlfiles
		return $?
	fi

	# we need openssl. let apk handle deps
	apk add --quiet --initdb --repositories-file $repofile openssl || return 1

	if ! openssl list -1 -cipher-commands | grep "^$suffix$" > /dev/null; then
		errstr="Cipher $suffix is not supported"
		return 1
	fi
	local count=0
	# beep
	echo -e "\007"
	while [ $count -lt 3 ]; do
		openssl enc -d -$suffix -in "$ovl" | tar --numeric-owner \
			-C "$dest" -zxv >$ovlfiles 2>/dev/null && return 0
		count=$(( $count + 1 ))
	done
	ovlfiles=
	return 1
}

# find mount dir for given device in an fstab
# returns global MNTOPTS
find_mnt() {
	local search_dev="$1"
	local fstab="$2"
	case "$search_dev" in
	UUID*|LABEL*) search_dev=$(findfs "$search_dev");;
	esac
	MNTOPTS=
	[ -r "$fstab" ] || return 1
	local search_maj_min=$(stat -L -c '%t,%T' $search_dev)
	while read dev mnt fs MNTOPTS chk; do
		case "$dev" in
		UUID*|LABEL*) dev=$(findfs "$dev");;
		esac
		if [ -b "$dev" ]; then
			local maj_min=$(stat -L -c '%t,%T' $dev)
			if [ "$maj_min" = "$search_maj_min" ]; then
				echo "$mnt"
				return
			fi
		fi
	done < $fstab
	MNTOPTS=
}

#  add a boot service to $sysroot
rc_add() {
	mkdir -p $sysroot/etc/runlevels/$2
	ln -sf /etc/init.d/$1 $sysroot/etc/runlevels/$2/$1
}

# Recursively resolve tty aliases like console or tty0
list_console_devices() {
	if ! [ -e /sys/class/tty/$1/active ]; then
		echo $1
		return
	fi

	for dev in $(cat /sys/class/tty/$1/active); do
		list_console_devices $dev
	done
}

setup_inittab_console(){
	term=vt100
	# Inquire the kernel for list of console= devices
	consoles="$(for c in console $KOPT_consoles; do list_console_devices $c; done)"
	for tty in $consoles; do
		# do nothing if inittab already have the tty set up
		if ! grep -q "^$tty:" $sysroot/etc/inittab; then
			echo "# enable login on alternative console" \
				>> $sysroot/etc/inittab
			# Baudrate of 0 keeps settings from kernel
			echo "$tty::respawn:/sbin/getty -L 0 $tty $term" \
				>> $sysroot/etc/inittab
		fi
		if [ -e "$sysroot"/etc/securetty ] && ! grep -q -w "$tty" "$sysroot"/etc/securetty; then
			echo "$tty" >> "$sysroot"/etc/securetty
		fi
	done
}

# determine the default interface to use if ip=dhcp is set
# uses the first "eth" interface with operstate 'up'.
ip_choose_if() {
	if [ -n "$KOPT_BOOTIF" ]; then
		mac=$(printf "%s\n" "$KOPT_BOOTIF"|sed 's/^01-//;s/-/:/g')
		dev=$(grep -l $mac /sys/class/net/*/address|head -n 1)
		dev=${dev%/*}
		[ -n "$dev" ] && echo "${dev##*/}" && return
	fi
	for x in /sys/class/net/eth*; do
		if grep -iq up $x/operstate;then
			[ -e "$x" ] && echo ${x##*/} && return
		fi
	done
	[ -e "$x" ] && echo ${x##*/} && return
}

# if "ip=dhcp" is specified on the command line, we obtain an IP address
# using udhcpc. we do this now and not by enabling kernel-mode DHCP because
# kernel-model DHCP appears to require that network drivers be built into
# the kernel rather than as modules. At this point all applicable modules
# in the initrd should have been loaded.
#
# You need af_packet.ko available as well modules for your Ethernet card.
#
# See https://www.kernel.org/doc/Documentation/filesystems/nfs/nfsroot.txt
# for documentation on the format.
#
# Valid syntaxes:
#   ip=client-ip:server-ip:gw-ip:netmask:hostname:device:autoconf:
#     :dns0-ip:dns1-ip:ntp0-ip
#   ip=dhcp
#   "server-ip", "hostname" and "ntp0-ip" are not supported here.
# Default (when configure_ip is called without setting ip=):
#   ip=dhcp
#
configure_ip() {
	[ -n "$MAC_ADDRESS" ] && return

	local IFS=':'
	set -- ${KOPT_ip:-dhcp}
	unset IFS

	local client_ip="$1"
	local gw_ip="$3"
	local netmask="$4"
	local device="$6"
	local autoconf="$7"
	local dns1="$8"
	local dns2="$9"

	case "$client_ip" in
		off|none) return;;
		dhcp) autoconf="dhcp";;
	esac

	[ -n "$device" ] || device=$(ip_choose_if)

	if [ -z "$device" ]; then
		echo "ERROR: IP requested but no network device was found"
		return 1
	fi

	if [ "$autoconf" = "dhcp" ]; then
		# automatic configuration
		if [ ! -e /usr/share/udhcpc/default.script ]; then
			echo "ERROR: DHCP requested but not present in initrd"
			return 1
		fi
		ebegin "Obtaining IP via DHCP ($device)"
		ifconfig "$device" 0.0.0.0
		udhcpc -i "$device" -f -q
		eend $?
	else
		# manual configuration
		[ -n "$client_ip" -a -n "$netmask" ] || return
		ebegin "Setting IP ($device)"
		if ifconfig "$device" "$client_ip" netmask "$netmask"; then
			[ -z "$gw_ip" ] || ip route add 0.0.0.0/0 via "$gw_ip" dev "$device"
		fi
		eend $?
	fi

	# Never executes if variables are empty
	for i in $dns1 $dns2; do
		echo "nameserver $i" >> /etc/resolv.conf
	done

	MAC_ADDRESS=$(cat /sys/class/net/$device/address)
}

# relocate mountpoint according given fstab
relocate_mount() {
	local fstab="${1}"
	local dir=
	if ! [ -e $repofile ]; then
		return
	fi
	while read dir; do
		# skip http(s)/ftp repos for netboot
		if ! [ -d "$dir" ]; then
			continue
		fi
		local dev=$(df -P "$dir" | tail -1 | awk '{print $1}')
		local mnt=$(find_mnt $dev $fstab)
		if [ -n "$mnt" ]; then
			local oldmnt=$(awk -v d=$dev '$1==d {print $2}' /proc/mounts)
			if [ "$oldmnt" != "$mnt" ]; then
				mkdir -p "$mnt"
				mount -o move "$oldmnt" "$mnt"
			fi
		fi
	done < $repofile
}

# find the dirs under ALPINE_MNT that are boot repositories
find_boot_repositories() {
	if [ -n "$ALPINE_REPO" ]; then
		echo "$ALPINE_REPO"
	else
		find /media/* -name .boot_repository -type f -maxdepth 3 \
			| sed 's:/.boot_repository$::'
	fi
}

setup_nbd() {
	modprobe -q nbd max_part=8 || return 1
	local IFS=, n=0
	set -- $KOPT_nbd
	unset IFS
	for ops; do
		local server="${ops%:*}"
		local port="${ops#*:}"
		local device="/dev/nbd${n}"
		[ -b "$device" ] || continue
		nbd-client "$server" "$port" "$device" && n=$((n+1))
	done
	[ "$n" != 0 ] || return 1
}

rtc_exists() {
	local rtc=
	for rtc in /dev/rtc /dev/rtc[0-9]*; do
		[ -e "$rtc" ] && break
	done
	[ -e "$rtc" ]
}

# This is used to predict if network access will be necessary
is_url() {
	case "$1" in
	http://*|https://*|ftp://*)
		return 0;;
	*)
		return 1;;
	esac
}

# Do some tasks to make sure mounting the ZFS pool is A-OK
prepare_zfs_root() {
	local _root_vol=${KOPT_root#ZFS=}
	local _root_pool=${_root_vol%%/*}

	# Force import if this has been imported on a different system previously.
	# Import normally otherwise
	if [ "$KOPT_zfs_force" = 1 ]; then
		zpool import -N -d /dev -f $_root_pool
	else
		zpool import -N -d /dev $_root_pool
	fi


	# Ask for encryption password
	if [ $(zpool list -H -o feature@encryption $_root_pool) = "active" ]; then
		local _encryption_root=$(zfs get -H -o value encryptionroot $_root_vol)
		if [ "$_encryption_root" != "-" ]; then
			eval zfs load-key $_encryption_root
		fi
	fi
}

/usr/bin/busybox mkdir -p /usr/bin /usr/sbin /proc /sys /dev $sysroot \
	/media/cdrom /media/usb /tmp /run/cryptsetup

# Spread out busybox symlinks and make them available without full path
#/usr/bin/busybox --install -s
export PATH=/usr/bin:/bin:/usr/sbin:/sbin

# Make sure /dev/null is a device node. If /dev/null does not exist yet, the command
# mounting the devtmpfs will create it implicitly as an file with the "2>" redirection.
# The -c check is required to deal with initramfs with pre-seeded device nodes without
# error message.
[ -c /dev/null ] || mknod -m 666 /dev/null c 1 3
mount -t sysfs -o noexec,nosuid,nodev sysfs /sys
mount -t devtmpfs -o exec,nosuid,mode=0755,size=2M devtmpfs /dev 2>/dev/null \
	|| mount -t tmpfs -o exec,nosuid,mode=0755,size=2M tmpfs /dev

# Make sure /dev/kmsg is a device node. Writing to /dev/kmsg allows the use of the
# earlyprintk kernel option to monitor early init progress. As above, the -c check
# prevents an error if the device node has already been seeded.
[ -c /dev/kmsg ] || mknod -m 660 /dev/kmsg c 1 11

mount -t proc -o noexec,nosuid,nodev proc /proc
# pty device nodes (later system will need it)
[ -c /dev/ptmx ] || mknod -m 666 /dev/ptmx c 5 2
[ -d /dev/pts ] || mkdir -m 755 /dev/pts
mount -t devpts -o gid=5,mode=0620,noexec,nosuid devpts /dev/pts

# shared memory area (later system will need it)
[ -d /dev/shm ] || mkdir /dev/shm
mount -t tmpfs -o nodev,nosuid,noexec shm /dev/shm

# read the kernel options. we need surve things like:
#  acpi_osi="!Windows 2006" xen-pciback.hide=(01:00.0)
set -- $(cat /proc/cmdline)

myopts="alpine_dev autodetect autoraid chart cryptroot cryptdm cryptheader cryptoffset
	cryptdiscards cryptkey debug_init dma init init_args keep_apk_new modules ovl_dev
	pkgs quiet root_size root usbdelay ip alpine_repo apkovl alpine_start splash
	blacklist overlaytmpfs overlaytmpfsflags rootfstype rootflags nbd resume s390x_net
	dasd ssh_key BOOTIF zfcp find_boot"

for opt; do
	case "$opt" in
	s|single|1)
		SINGLEMODE=yes
		continue
		;;
	console=*)
		opt="${opt#*=}"
		KOPT_consoles="${opt%%,*} $KOPT_consoles"
		switch_root_opts="-c /dev/${opt%%,*}"
		continue
		;;
	esac

	for i in $myopts; do
		case "$opt" in
		$i=*)	eval "KOPT_${i}"='${opt#*=}';;
		$i)	eval "KOPT_${i}=yes";;
		no$i)	eval "KOPT_${i}=no";;
		esac
	done
done

echo "SLES-EVE Init $VERSION" > /dev/kmsg
[ "$KOPT_quiet" = yes ] || echo "Alpine Init $VERSION"

# enable debugging if requested
[ -n "$KOPT_debug_init" ] && set -x

# set default values
: ${KOPT_init:=/sbin/init}

# pick first keymap if found
for map in /etc/keymap/*; do
	if [ -f "$map" ]; then
		ebegin "Setting keymap ${map##*/}"
		zcat "$map" | loadkmap
		eend
		break
	fi
done

# start bootcharting if wanted
if [ "$KOPT_chart" = yes ]; then
	ebegin "Starting bootchart logging"
	/sbin/bootchartd start-initfs "$sysroot"
	eend 0
fi

# The following values are supported:
#   alpine_repo=auto	 -- default, search for .boot_repository
#   alpine_repo=http://...   -- network repository
ALPINE_REPO=${KOPT_alpine_repo}
[ "$ALPINE_REPO" = "auto" ] && ALPINE_REPO=

# hide kernel messages
[ "$KOPT_quiet" = yes ] && dmesg -n 1

# optional blacklist
for i in ${KOPT_blacklist//,/ }; do
	echo "blacklist $i" >> /etc/modprobe.d/boot-opt-blacklist.conf
done

# determine if we are going to need networking
if [ -n "$KOPT_ip" ] || [ -n "$KOPT_nbd" ] || \
	is_url "$KOPT_apkovl" || is_url "$ALPINE_REPO"; then

	do_networking=true
else
	do_networking=false
fi

if [ -n "$KOPT_zfcp" ]; then
	modprobe zfcp
	for _zfcp in $(echo "$KOPT_zfcp" | tr ',' ' ' | tr [A-Z] [a-z]); do
		echo 1 > /sys/bus/ccw/devices/"${_zfcp%%:*}"/online
	done
fi

if [ -n "$KOPT_dasd" ]; then
	for mod in dasd_mod dasd_eckd_mod dasd_fba_mod; do
		modprobe $mod
	done
	for _dasd in $(echo "$KOPT_dasd" | tr ',' ' ' | tr [A-Z] [a-z]); do
		echo 1 > /sys/bus/ccw/devices/"${_dasd%%:*}"/online
	done
fi

if [ "${KOPT_s390x_net%%,*}" = "qeth_l2" ]; then
	for mod in qeth qeth_l2 qeth_l3; do
		modprobe $mod
	done
	_channel="$(echo ${KOPT_s390x_net#*,} | tr [A-Z] [a-z])"
	echo "$_channel" > /sys/bus/ccwgroup/drivers/qeth/group
	echo 1 > /sys/bus/ccwgroup/drivers/qeth/"${_channel%%,*}"/layer2
	echo 1 > /sys/bus/ccwgroup/drivers/qeth/"${_channel%%,*}"/online
fi

# make sure we load zfs module if root=ZFS=...
rootfstype=${KOPT_rootfstype}
if [ -z "$rootfstype" ]; then
	case "$KOPT_root" in
	ZFS=*) rootfstype=zfs ;;
	esac
fi

# load available drivers to get access to modloop media
ebegin "Loading boot drivers"

modprobe -a $(echo "$KOPT_modules $rootfstype" | tr ',' ' ' ) loop squashfs simpledrm 2> /dev/null
if [ -f /etc/modules ] ; then
	sed 's/\#.*//g' < /etc/modules |
	while read module args; do
		modprobe -q $module $args
	done
fi
eend 0

# workaround for vmware
if grep -q VMware /sys/devices/virtual/dmi/id/sys_vendor 2>/dev/null; then
	modprobe -a ata_piix mptspi sr-mod
fi

if [ -n "$KOPT_cryptroot" ]; then
	cryptopts="-c ${KOPT_cryptroot}"
	if [ "$KOPT_cryptdiscards" = "yes" ]; then
		cryptopts="$cryptopts -D"
	fi
	if [ -n "$KOPT_cryptdm" ]; then
		cryptopts="$cryptopts -m ${KOPT_cryptdm}"
	fi
	if [ -n "$KOPT_cryptheader" ]; then
		cryptopts="$cryptopts -H ${KOPT_cryptheader}"
	fi
	if [ -n "$KOPT_cryptoffset" ]; then
		cryptopts="$cryptopts -o ${KOPT_cryptoffset}"
	fi
	if [ "$KOPT_cryptkey" = "yes" ]; then
		cryptopts="$cryptopts -k /crypto_keyfile.bin"
	elif [ -n "$KOPT_cryptkey" ]; then
		cryptopts="$cryptopts -k ${KOPT_cryptkey}"
	fi
fi

if [ -n "$KOPT_nbd" ]; then
	# TODO: Might fail because nlplug-findfs hasn't plugged eth0 yet
	configure_ip
	setup_nbd || echo "Failed to setup nbd device."
fi

# zpool reports /dev/zfs missing if it can't read /etc/mtab
ln -s /proc/mounts /etc/mtab

# let's see if we were told to identify a boot partition
if [ -n "$KOPT_find_boot" ]; then
        # locate boot media and mount it
        # NOTE that we may require up to 3 tries with
        # 30 seconds pauses between them to accomodate
        # really slow controllers (such as bad USB sticks)
	#* HACK, nlplug-findfs doesn't seem to return,
	#*  so running it in the background, and kill
	#*  the process so it doesn't get in the way
	last_nlpug=0
        for i in 0 1 2; do
                ebegin "Attempt $i to find and mount boot media"
                MEDIA_ID=$(grep -l "$KOPT_find_boot" /media/*/boot/.uuid 2>/dev/null)
                if [ -n "$MEDIA_ID" ]; then
                        mkdir -p /media/boot
                        mount --bind "/media/$(echo "$MEDIA_ID" | cut -f3 -d/)" /media/boot
                        break
                fi
                sleep $(( i * 30 ))
		#* hack code
		if [ last_nlplug != 0 ]; then
			kill $(( last_nlplug ))
			last_nlplug=0
		fi
		#* end hack
                nlplug-findfs $cryptopts -p /sbin/mdev ${KOPT_debug_init:+-d} \
                   ${KOPT_usbdelay:+-t $(( $KOPT_usbdelay * 1000 ))} \
                   -n -b $repofile -a /tmp/apkovls &
		#* seems to never return...
		last_nlplug=$!
                #* eend $result
        done
	#* hack code
	if [ last_nlplug != 0 ]; then
		kill $(( last_nlplug ))
		last_nlplug=0
	fi
	#* end hack
        # if we didn't find anything, but were asked to -- treat it
        # as an error condition (it maybe transient, but it needs to
        # be corrected
        if [ -z "$MEDIA_ID" ]; then
                echo "Failed to identify boot media. Try to re-run nlplug-findfs manually to see what's wrong:"
                echo "  nlplug-findfs -p /sbin/mdev -d -t 30000 -n  -n -b $repofile -a /tmp/apkovls"
                echo "once you find boot device, run:"
                echo "  mount --bind /media/XXX /media/boot"
                echo "and then exit the shell."
                sh
        fi
fi

# check if root=... was set
if [ -n "$KOPT_root" ]; then
	if [ "$SINGLEMODE" = "yes" ]; then
		echo "Entering single mode. Type 'exit' to continue booting."
		sh
	fi

	ebegin "Mounting root"
        if [ -f "$KOPT_root" ]; then
                LOOP_IMG=$(realpath "$KOPT_root")
                # workingaround linux kernel's desire to lump the entire
                # set of initrd images into /initrd.image
                if [ "$LOOP_IMG" = /initrd.image ]; then
                        OFFSET=$(LANG=C grep -obUaP hsqs /initrd.image|cut -f1 -d:|head -1)
                        if [ -n "$OFFSET" ]; then
                                LOSETUP_EXTRA_OPTS="-o$OFFSET"
                        fi
                fi

                KOPT_root=$(losetup -f)
                losetup $LOSETUP_EXTRA_OPTS -r -f "$LOOP_IMG"
        else
                nlplug-findfs $cryptopts -p /sbin/mdev ${KOPT_debug_init:+-d} \
                        $KOPT_root
        fi

	if echo "$KOPT_modules $rootfstype" | grep -qw btrfs; then
		/sbin/btrfs device scan >/dev/null || \
			echo "Failed to scan devices for btrfs filesystem."
	fi

	if [ -n "$KOPT_resume" ]; then
		echo "Resume from disk"
		if [ -e /sys/power/resume ]; then
			case "$KOPT_resume" in
			UUID*|LABEL*) resume_dev=$(findfs "$KOPT_resume");;
			*) resume_dev="$KOPT_resume";;
			esac
			printf "%d:%d" $(stat -Lc "0x%t 0x%T" "$resume_dev") >/sys/power/resume
		else
			echo "resume: no hibernation support found"
		fi
	fi

	if [ "$KOPT_overlaytmpfs" = "yes" ]; then
		# Create mountpoints
		mkdir -p /media/root-ro /media/root-rw $sysroot/media/root-ro \
			$sysroot/media/root-rw
		# Mount read-only underlying rootfs
		rootflags="${KOPT_rootflags:+$KOPT_rootflags,}ro"
		mount ${KOPT_rootfstype:+-t $KOPT_rootfstype} -o $rootflags \
			$KOPT_root /media/root-ro
		# Mount writable overlay tmpfs
		# overlaytmpfsflags="mode=0755,${KOPT_overlaytmpfsflags:+$KOPT_overlaytmpfsflags,}rw"
		# mount -t tmpfs -o $overlaytmpfsflags root-tmpfs /media/root-rw
		# Create additional mountpoints and do the overlay mount
		mkdir -p /media/root-rw/work /media/root-rw/root
		mount -t overlay -o \
			lowerdir=/media/root-ro,upperdir=/media/root-rw/root,workdir=/media/root-rw/work \
			overlayfs $sysroot
		# this protects /media/root-rw from being destroyed by switch_root
		mount -t proc proc /media/root-rw
	else
		if [ "$rootfstype" = "zfs" ]; then
			prepare_zfs_root
		fi
		mount ${rootfstype:+-t} ${rootfstype} \
			-o ${KOPT_rootflags:-ro} \
			${KOPT_root#ZFS=} $sysroot
	fi

	eend $?
	grep -vE '^(proc|sysfs|devtmpfs|devpts|shm) ' /proc/mounts | while read DEV DIR TYPE OPTS ; do
		if [ "$DIR" != "/" -a "$DIR" != "$sysroot" -a -d "$DIR" ]; then
			mkdir -p $sysroot/$DIR
			mount -o move $DIR $sysroot/$DIR
		fi
	done
	sync

	exec /usr/bin/busybox switch_root $switch_root_opts $sysroot $chart_init "$KOPT_init" $KOPT_init_args
	echo "initramfs emergency recovery shell launched"
	exec /usr/bin/busybox sh
fi
echo "do_networking"
if $do_networking; then
	repoopts="-n"
else
	repoopts="-b $repofile"
fi

# locate boot media and mount it
ebegin "Mounting boot media"
nlplug-findfs $cryptopts -p /sbin/mdev ${KOPT_debug_init:+-d} \
	${KOPT_usbdelay:+-t $(( $KOPT_usbdelay * 1000 ))} \
	$repoopts -a /tmp/apkovls
eend $?

# Setup network interfaces
if $do_networking; then
	configure_ip
fi

# early console?
if [ "$SINGLEMODE" = "yes" ]; then
	echo "Entering single mode. Type 'exit' to continue booting."
	sh
fi

# mount tmpfs sysroot
rootflags="mode=0755"
if [ -n "$KOPT_root_size" ]; then
	echo "WARNING: the boot option root_size is deprecated. Use rootflags instead"
	rootflags="$rootflags,size=$KOPT_root_size"
fi
if [ -n "$KOPT_rootflags" ]; then
	rootflags="$rootflags,$KOPT_rootflags"
fi

mount -t tmpfs -o $rootflags tmpfs $sysroot

if [ -z "$KOPT_apkovl" ]; then
	# Not manually set, use the apkovl found by nlplug
	if [ -e /tmp/apkovls ]; then
		ovl=$(head -n 1 /tmp/apkovls)
	fi
elif is_url "$KOPT_apkovl"; then
	# Fetch apkovl via network
	MACHINE_UUID=$(cat /sys/class/dmi/id/product_uuid 2>/dev/null)
	url="${KOPT_apkovl/{MAC\}/$MAC_ADDRESS}"
	url="${url/{UUID\}/$MACHINE_UUID}"
	ovl=/tmp/${url##*/}
	wget -O "$ovl" "$url" || ovl=
else
	ovl="$KOPT_apkovl"
fi

# parse pkgs=pkg1,pkg2
if [ -n "$KOPT_pkgs" ]; then
	pkgs=$(echo "$KOPT_pkgs" | tr ',' ' ' )
fi

# load apkovl or set up a minimal system
if [ -f "$ovl" ]; then
	ebegin "Loading user settings from $ovl"
	# create apk db and needed /dev/null and /tmp first
	apk add --root $sysroot --initdb --quiet

	unpack_apkovl "$ovl" $sysroot
	eend $? $errstr || ovlfiles=
	# hack, incase /root/.ssh was included in apkovl
	[ -d "$sysroot/root" ] && chmod 700 "$sysroot/root"
	pkgs="$pkgs $(cat $sysroot/etc/apk/world 2>/dev/null)"
fi

if [ -f "$sysroot/etc/.default_boot_services" -o ! -f "$ovl" ]; then
	# add some boot services by default
	rc_add devfs sysinit
	rc_add dmesg sysinit
	rc_add mdev sysinit
	rc_add hwdrivers sysinit
	rc_add modloop sysinit

	rc_add modules boot
	rc_add sysctl boot
	rc_add hostname boot
	rc_add bootmisc boot
	rc_add syslog boot

	rc_add mount-ro shutdown
	rc_add killprocs shutdown
	rc_add savecache shutdown

	rc_add firstboot default

	# add openssh
	if [ -n "$KOPT_ssh_key" ]; then
		pkgs="$pkgs openssh"
		rc_add sshd default
	fi

	rm -f "$sysroot/etc/.default_boot_services"
fi

if [ "$KOPT_splash" != "no" ]; then
	echo "IMG_ALIGN=CM" > /tmp/fbsplash.cfg
	for fbdev in /dev/fb[0-9]; do
		[ -e "$fbdev" ] || break
		num="${fbdev#/dev/fb}"
		for img in /media/*/fbsplash$num.ppm; do
			[ -e "$img" ] || break
			config="${img%.*}.cfg"
			[ -e "$config" ] || config=/tmp/fbsplash.cfg
			fbsplash -s "$img" -d "$fbdev" -i "$config"
			break
		done
	done
	for fbsplash in /media/*/fbsplash.ppm; do
		[ -e "$fbsplash" ] && break
	done
fi

if [ -n "$fbsplash" ] && [ -e "$fbsplash" ]; then
	ebegin "Starting bootsplash"
	mkfifo $sysroot/$splashfile
	config="${fbsplash%.*}.cfg"
	[ -e "$config" ] || config=/tmp/fbsplash.cfg
	setsid fbsplash -T 16 -s "$fbsplash" -i $config -f $sysroot/$splashfile &
	eend 0
else
	KOPT_splash="no"
fi

if [ -f $sysroot/etc/fstab ]; then
	has_fstab=1
	fstab=$sysroot/etc/fstab

	# let user override tmpfs size in fstab in apkovl
	mountopts=$(awk '$2 == "/" && $3 == "tmpfs" { print $4 }' $sysroot/etc/fstab)
	if [ -n "$mountopts" ]; then
		mount -o remount,$mountopts $sysroot
	fi
	# move the ALPINE_MNT if ALPINE_DEV is specified in users fstab
	# this is so a generated /etc/apk/repositories will use correct
	# mount dir
	relocate_mount "$sysroot"/etc/fstab
elif [ -f /etc/fstab ]; then
	relocate_mount /etc/fstab
fi

# hack so we get openrc
pkgs="$pkgs alpine-base"

# copy keys so apk finds them. apk looks for stuff relative --root
mkdir -p $sysroot/etc/apk/keys/
cp -a /etc/apk/keys $sysroot/etc/apk

# generate apk repositories file. needs to be done after relocation
find_boot_repositories > $repofile

# silently fix apk arch in case the apkovl does not match
if [ -r "$sysroot"/etc/apk/arch ]; then
	apk_arch="$(apk --print-arch)"
	if [ -n "$apk_arch" ]; then
		echo "$apk_arch" > "$sysroot"/etc/apk/arch
	fi
fi

# generate repo opts for apk
for i in $(cat $repofile); do
	repo_opt="$repo_opt --repository $i"
done

# install new root
ebegin "Installing packages to root filesystem"

if [ "$KOPT_chart" = yes ]; then
	pkgs="$pkgs acct"
fi

# use swclock if no RTC is found
if rtc_exists || [ "$(uname -m)" = "s390x" ]; then
	rc_add hwclock boot
else
	rc_add swclock boot
fi

# enable support for modloop verification
if [ -f /var/cache/misc/*modloop*.SIGN.RSA.*.pub ]; then
	mkdir -p "$sysroot"/var/cache/misc
	cp /var/cache/misc/*modloop*.SIGN.RSA.*.pub "$sysroot"/var/cache/misc
	pkgs="$pkgs openssl"
fi

apkflags="--initramfs-diskless-boot --progress"
if [ -z "$MAC_ADDRESS" ]; then
	apkflags="$apkflags --no-network"
else
	apkflags="$apkflags --update-cache"
fi

if [ "$KOPT_quiet" = yes ]; then
	apkflags="$apkflags --quiet"
fi

if [ "$KOPT_keep_apk_new" != yes ]; then
	apkflags="$apkflags --clean-protected"
	[ -n "$ovlfiles" ] && apkflags="$apkflags --overlay-from-stdin"
fi
mkdir -p $sysroot/sys $sysroot/proc $sysroot/dev
mount -o bind /sys $sysroot/sys
mount -o bind /proc $sysroot/proc
mount -o bind /dev $sysroot/dev
if [ -n "$ovlfiles" ]; then
	apk add --root $sysroot $repo_opt $apkflags $pkgs <$ovlfiles
else
	apk add --root $sysroot $repo_opt $apkflags $pkgs
fi
umount $sysroot/sys $sysroot/proc $sysroot/dev
eend $?

# unmount ovl mount if needed
if [ -n "$ovl_unmount" ]; then
	umount $ovl_unmount 2>/dev/null
fi

# remount according default fstab from package
if [ -z "$has_fstab" ] && [ -f "$sysroot"/etc/fstab ]; then
	relocate_mount "$sysroot"/etc/fstab
fi

# generate repositories if none exists. this needs to be done after relocation
if ! [ -f "$sysroot"/etc/apk/repositories ]; then
	find_boot_repositories > "$sysroot"/etc/apk/repositories
fi

# respect mount options in fstab for ALPINE_MNT (e.g if user wants rw)
if [ -f "$sysroot"/etc/fstab ]; then
	opts=$(awk "\$2 == \"$ALPINE_MNT\" {print \$4}" $sysroot/etc/fstab)
	if [ -n "$opts" ]; then
		mount -o remount,$opts "$ALPINE_MNT"
	fi
fi

# fix inittab if alternative console
setup_inittab_console

# copy alpine release info
#if ! [ -f "$sysroot"/etc/alpine-release ] && [ -f $ALPINE_MNT/.alpine-release ]; then
#	cp $ALPINE_MNT/.alpine-release $sysroot/
#	ln -sf /.alpine-release $sysroot/etc/alpine-release
#fi

! [ -f "$sysroot"/etc/resolv.conf ] && [ -f /etc/resolv.conf ] && \
	cp /etc/resolv.conf "$sysroot"/etc

# setup bootchart for switch_root
echo "Start bootchart"
chart_init=""
if [ "$KOPT_chart" = yes ]; then
	/sbin/bootchartd stop-initfs "$sysroot"
	chart_init="/sbin/bootchartd start-rootfs"
fi

if [ ! -x "${sysroot}${KOPT_init}" ]; then
	[ "$KOPT_splash" != "no" ] && echo exit > $sysroot/$splashfile
	echo "$KOPT_init not found in new root. Launching emergency recovery shell"
	echo "Type exit to continue boot."
	/usr/bin/busybox sh
fi
echo "Done with it ======================="
delay 15
# switch over to new root
cat /proc/mounts | while read DEV DIR TYPE OPTS ; do
	if [ "$DIR" != "/" -a "$DIR" != "$sysroot" -a -d "$DIR" ]; then
		mkdir -p $sysroot/$DIR
		mount -o move $DIR $sysroot/$DIR
	fi
done
sync

[ "$KOPT_splash" = "init" ] && echo exit > $sysroot/$splashfile
echo ""
exec /usr/bin/busybox switch_root $switch_root_opts $sysroot $chart_init "$KOPT_init" $KOPT_init_args

[ "$KOPT_splash" != "no" ] && echo exit > $sysroot/$splashfile
echo "initramfs emergency recovery shell launched"
exec /usr/bin/busybox sh
reboot
