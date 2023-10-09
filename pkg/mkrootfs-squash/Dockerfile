FROM lfedge/eve-rhel:fd11ea87f91a90596f75c4f2aba61b13704f7fa0-dirty-399c4aa AS build

ENV PKGS dosfstools bsdtar binutils mtools util-linux-ng gdisk \
    xfsprogs e2fsprogs util-linux coreutils device-mapper-multipath \
    squashfs-tools glibc-devel
RUN eve-rhel-deploy.sh

COPY . /out/

FROM scratch
COPY --from=build /out/ /
ENTRYPOINT [ "/make-rootfs" ]
