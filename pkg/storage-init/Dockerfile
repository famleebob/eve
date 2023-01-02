FROM lfedge/eve-suse:7d66f557e844047f0740535c5d5178af0f10be04 as build
ENV PKGS bash squashfs-tools util-linux e2fsprogs keyutils dosfstools coreutils sgdisk smartmontools
RUN eve-suse-deploy.sh

FROM scratch
COPY --from=build /out/ /
COPY storage-init.sh /

WORKDIR /
ENTRYPOINT []
CMD ["/storage-init.sh"]
