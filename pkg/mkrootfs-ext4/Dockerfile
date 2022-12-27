FROM lfedge/eve-suse:c44c0bbfa6d2ecd892de235362d2c635c6475090 AS build

ENV BUILD_PKGS tar
ENV PKGS libarchive13 mtools \
         squashfs
RUN eve-suse-deploy.sh

COPY . /out/

FROM scratch
COPY --from=build /out/ /
ENTRYPOINT [ "/make-rootfs" ]
