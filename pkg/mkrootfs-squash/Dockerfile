FROM lfedge/eve-suse:8c48adb6dc81928dfc1016e2ee44c4b18cacbeb2 AS build

#* Alpine sfdisk package just provides the utility from util-linux
#*  which we install, and not found in another package
ENV PKGS dosfstools libarchive-devel binutils mtools coreutils gptfdisk \
	xfsprogs e2fsprogs util-linux coreutils multipath-tools squashfs \
	systemd-sysvinit
ENV BUILD_PKGS tar bsdtar
RUN eve-suse-deploy.sh

COPY . /out/

FROM scratch
COPY --from=build /out/ /
ENTRYPOINT [ "/make-rootfs" ]
