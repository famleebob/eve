FROM lfedge/eve-rhel:9ad685cd8abb440ce4c7101bf5f0a828f3a525dd-dirty-aa26ab2 as build
ENV PKGS bash glib2 squashfs-tools util-linux e2fsprogs keyutils dosfstools \
         coreutils gdisk smartmontools pam-devel
RUN eve-rhel-deploy.sh

FROM scratch
COPY --from=build /out/ /
COPY storage-init.sh /

WORKDIR /
ENTRYPOINT []
CMD ["/storage-init.sh"]
