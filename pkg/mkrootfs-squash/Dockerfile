FROM lfedge/eve-suse:263a9793e6b21aae48083a653552bec245ee1a92 AS build

#* some of the packages are provided as part of the SuSE busybox
ENV PKGS libarchive13 mtools gptfdisk \
    squashfs
ENV BUILD_PKGS tar
RUN eve-suse-deploy.sh
RUN zypper --ignore-unknown --non-interactive install --no-confirm --no-recommends --force xfsprogs


COPY . /out/

FROM scratch
COPY --from=build /out/ /
ENTRYPOINT [ "/make-rootfs" ]
