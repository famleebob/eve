FROM lfedge/eve-rhel:fd11ea87f91a90596f75c4f2aba61b13704f7fa0-dirty-399c4aa as build
ENV PKGS bash glib2 squashfs-tools util-linux e2fsprogs keyutils dosfstools \
         coreutils gdisk smartmontools pam-devel
RUN eve-rhel-deploy.sh

FROM scratch
COPY --from=build /out/ /
COPY storage-init.sh /

WORKDIR /
ENTRYPOINT []
CMD ["/storage-init.sh"]
