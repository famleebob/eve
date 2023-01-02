FROM lfedge/eve-suse:7d66f557e844047f0740535c5d5178af0f10be04 AS build

#* some of the packages are provided as part of the SuSE busybox
ENV PKGS libarchive13 mtools gptfdisk \
    xfsprogs squashfs
ENV BUILD_PKGS tar
RUN eve-suse-deploy.sh

COPY . /out/

FROM scratch
COPY --from=build /out/ /
ENTRYPOINT [ "/make-rootfs" ]
