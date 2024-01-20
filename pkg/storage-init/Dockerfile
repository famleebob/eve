FROM lfedge/eve-rhel:c215632c87d22f89ab2d20aebe3d66462e793b20-dirty-aac5fba as build
ENV PKGS bash glib2 squashfs-tools util-linux e2fsprogs keyutils dosfstools \
         coreutils gdisk smartmontools pam-devel
RUN eve-rhel-deploy.sh

FROM scratch
COPY --from=build /out/ /
COPY storage-init.sh /

WORKDIR /
ENTRYPOINT []
CMD ["/storage-init.sh"]
