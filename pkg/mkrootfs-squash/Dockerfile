FROM lfedge/eve-suse:2f1c38631c5199f885ef4ddde47108a7cb5e6e2d AS build

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
