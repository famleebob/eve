FROM lfedge/eve-suse:7d66f557e844047f0740535c5d5178af0f10be04 AS build

ENV BUILD_PKGS tar
ENV PKGS libarchive13 mtools \
         squashfs
RUN eve-suse-deploy.sh

COPY . /out/

FROM scratch
COPY --from=build /out/ /
ENTRYPOINT [ "/make-rootfs" ]
