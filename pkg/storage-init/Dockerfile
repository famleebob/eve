FROM lfedge/eve-suse:0e399fa0bfb2afbbe433313c3cd19b0e988ed80c as build

ENV PKGS bash squashfs util-linux e2fsprogs keyutils dosfstools coreutils \
	gptfdisk coreutils smartmontools systemd-sysvinit parted

RUN eve-suse-deploy.sh

FROM scratch
COPY --from=build /out/ /
COPY storage-init.sh /

WORKDIR /
ENTRYPOINT []
CMD ["/storage-init.sh"]
