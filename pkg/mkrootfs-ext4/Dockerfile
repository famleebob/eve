FROM lfedge/eve-suse:263a9793e6b21aae48083a653552bec245ee1a92 AS build

ENV BUILD_PKGS tar
ENV PKGS libarchive13 mtools \
         squashfs
RUN eve-suse-deploy.sh

COPY . /out/

FROM scratch
COPY --from=build /out/ /
ENTRYPOINT [ "/make-rootfs" ]
