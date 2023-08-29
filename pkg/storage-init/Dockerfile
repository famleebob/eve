FROM lfedge/eve-rhel:62fdc6097dac8f1936bd28f85ef29a2cb7582c03-dirty-c07b0bc as build
ENV PKGS bash glib2 squashfs-tools util-linux e2fsprogs keyutils dosfstools \
         coreutils gdisk smartmontools pam-devel
RUN eve-rhel-deploy.sh

FROM scratch
COPY --from=build /out/ /
COPY storage-init.sh /

WORKDIR /
ENTRYPOINT []
CMD ["/storage-init.sh"]
