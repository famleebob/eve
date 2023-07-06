FROM lfedge/eve-suse:8f41da0470c198d5da94d2d05eefebcaa72cd75a as build

ENV PKGS bash squashfs util-linux e2fsprogs keyutils dosfstools coreutils \
	gptfdisk coreutils smartmontools systemd-sysvinit parted

RUN eve-suse-deploy.sh

FROM scratch
COPY --from=build /out/ /
COPY storage-init.sh /

WORKDIR /
ENTRYPOINT []
CMD ["/storage-init.sh"]
