FROM lfedge/eve-suse:4b46a3406cf79786e2e0aba3cdc60ed16aa20de2 AS build

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
