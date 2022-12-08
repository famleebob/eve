FROM lfedge/eve-suse:94e897dd63b16092d301dc51cae9ec5df3dd0222 as build
ENV PKGS bash squashfs-tools util-linux e2fsprogs keyutils dosfstools coreutils sgdisk smartmontools
RUN eve-suse-deploy.sh

FROM scratch
COPY --from=build /out/ /
COPY storage-init.sh /

WORKDIR /
ENTRYPOINT []
CMD ["/storage-init.sh"]
