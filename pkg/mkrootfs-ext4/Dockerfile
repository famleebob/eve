FROM lfedge/eve-suse:2f1c38631c5199f885ef4ddde47108a7cb5e6e2d AS build

ENV BUILD_PKGS tar
ENV PKGS libarchive13 mtools \
         squashfs
RUN eve-suse-deploy.sh

COPY . /out/

FROM scratch
COPY --from=build /out/ /
ENTRYPOINT [ "/make-rootfs" ]
