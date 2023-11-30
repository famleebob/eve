FROM lfedge/eve-rhel:8c785ecb375912be79d40433553247b0a17b879e-dirty-91c7b8c as build
ENV PKGS bash glib2 squashfs-tools util-linux e2fsprogs keyutils dosfstools \
         coreutils gdisk smartmontools pam-devel
RUN eve-rhel-deploy.sh

FROM scratch
COPY --from=build /out/ /
COPY storage-init.sh /

WORKDIR /
ENTRYPOINT []
CMD ["/storage-init.sh"]
