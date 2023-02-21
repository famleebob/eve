FROM lfedge/eve-suse:8c48adb6dc81928dfc1016e2ee44c4b18cacbeb2 as build

ENV PKGS bash squashfs util-linux e2fsprogs keyutils dosfstools coreutils \
	gptfdisk coreutils smartmontools systemd-sysvinit
RUN eve-suse-deploy.sh

FROM scratch
COPY --from=build /out/ /
COPY storage-init.sh /

WORKDIR /
ENTRYPOINT []
CMD ["/storage-init.sh"]
