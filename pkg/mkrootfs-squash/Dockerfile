FROM lfedge/eve-suse:6be054ed61f0d9d9d91f04cbfaef8c91ae606003 AS build

#* some of the packages are provided as part of the SuSE busybox
ENV PKGS libarchive13 mtools gptfdisk \
    xfsprogs squashfs
ENV BUILD_PKGS tar
RUN eve-suse-deploy.sh

COPY . /out/

FROM scratch
COPY --from=build /out/ /
ENTRYPOINT [ "/make-rootfs" ]
