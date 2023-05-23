FROM lfedge/eve-suse:5b666917dbdbbbe9ccce73eead47f860ae96473c AS build

ENV BUILD_PKGS tar bsdtar
#* Alpine sfdisk package just provides the utility from util-linux
#*  which we install, and not found in another package
ENV PKGS dosfstools libarchive-devel binutils mtools coreutils gptfdisk \
	xfsprogs e2fsprogs util-linux coreutils multipath-tools squashfs \
	systemd-sysvinit bsdtar
RUN eve-suse-deploy.sh

COPY . /out/

FROM scratch
COPY --from=build /out/ /
ENTRYPOINT [ "/make-rootfs" ]
