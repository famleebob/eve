FROM lfedge/eve-suse:c44c0bbfa6d2ecd892de235362d2c635c6475090 AS build

#* some of the packages are provided as part of the SuSE busybox
ENV PKGS libarchive13 mtools gptfdisk \
    xfsprogs squashfs
ENV BUILD_PKGS tar
RUN eve-suse-deploy.sh

COPY . /out/

FROM scratch
COPY --from=build /out/ /
ENTRYPOINT [ "/make-rootfs" ]
