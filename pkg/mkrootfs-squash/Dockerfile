FROM lfedge/eve-suse:c055c434cf56a79abfdb33f37e482f7c26efab9d AS build

#* Alpine sfdisk package just provides the utility from util-linux
#*  which we install, and not found in another package
ENV PKGS dosfstools libarchive-devel binutils mtools coreutils gptfdisk \
	xfsprogs e2fsprogs util-linux coreutils multipath-tools squashfs \
	systemd-sysvinit bsdtar
ENV BUILD_PKGS tar bsdtar
RUN eve-suse-deploy.sh

COPY . /out/

FROM scratch
COPY --from=build /out/ /
ENTRYPOINT [ "/make-rootfs" ]
