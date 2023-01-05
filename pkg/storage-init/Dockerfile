FROM lfedge/eve-suse:263a9793e6b21aae48083a653552bec245ee1a92 as build
ENV PKGS bash squashfs-tools util-linux e2fsprogs keyutils dosfstools coreutils sgdisk smartmontools
RUN eve-suse-deploy.sh

FROM scratch
COPY --from=build /out/ /
COPY storage-init.sh /

WORKDIR /
ENTRYPOINT []
CMD ["/storage-init.sh"]
