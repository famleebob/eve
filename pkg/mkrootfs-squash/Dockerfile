FROM lfedge/eve-rhel:8c785ecb375912be79d40433553247b0a17b879e-dirty-91c7b8c AS build

ENV PKGS dosfstools bsdtar binutils mtools util-linux-ng gdisk \
    xfsprogs e2fsprogs util-linux coreutils device-mapper-multipath \
    squashfs-tools glibc-devel elfutils-debuginfod-client
RUN eve-rhel-deploy.sh

COPY . /out/

FROM scratch
COPY --from=build /out/ /
ENTRYPOINT [ "/make-rootfs" ]
