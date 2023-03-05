FROM lfedge/eve-suse:1935168cce9da9d6664645f7dab27d23a7ab258e as build

ENV PKGS bash squashfs util-linux e2fsprogs keyutils dosfstools coreutils \
	gptfdisk coreutils smartmontools systemd-sysvinit parted

RUN eve-suse-deploy.sh

FROM scratch
COPY --from=build /out/ /
COPY storage-init.sh /

WORKDIR /
ENTRYPOINT []
CMD ["/storage-init.sh"]
