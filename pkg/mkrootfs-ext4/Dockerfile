FROM lfedge/eve-suse:8f41da0470c198d5da94d2d05eefebcaa72cd75a AS build

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
