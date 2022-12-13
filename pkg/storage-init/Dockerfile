FROM lfedge/eve-suse:6be054ed61f0d9d9d91f04cbfaef8c91ae606003 as build
ENV PKGS bash squashfs-tools util-linux e2fsprogs keyutils dosfstools coreutils sgdisk smartmontools
RUN eve-suse-deploy.sh

FROM scratch
COPY --from=build /out/ /
COPY storage-init.sh /

WORKDIR /
ENTRYPOINT []
CMD ["/storage-init.sh"]
