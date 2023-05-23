FROM lfedge/eve-suse:5b666917dbdbbbe9ccce73eead47f860ae96473c as build

ENV PKGS bash squashfs util-linux e2fsprogs keyutils dosfstools coreutils \
	gptfdisk coreutils smartmontools systemd-sysvinit parted

RUN eve-suse-deploy.sh

FROM scratch
COPY --from=build /out/ /
COPY storage-init.sh /

WORKDIR /
ENTRYPOINT []
CMD ["/storage-init.sh"]
