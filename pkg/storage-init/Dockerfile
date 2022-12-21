FROM lfedge/eve-suse:7595cac560afd50d82093da86567899883918377 as build
ENV PKGS bash squashfs-tools util-linux e2fsprogs keyutils dosfstools coreutils sgdisk smartmontools
RUN eve-suse-deploy.sh

FROM scratch
COPY --from=build /out/ /
COPY storage-init.sh /

WORKDIR /
ENTRYPOINT []
CMD ["/storage-init.sh"]
