FROM lfedge/eve-suse:c30aba4558a5f755e2875f8cdf48c4e46d31a29f AS build

#* some of the packages are provided as part of the SuSE busybox
ENV PKGS libarchive13 mtools gptfdisk \
    squashfs bsdtar
ENV BUILD_PKGS tar bsdtar
RUN eve-suse-deploy.sh
RUN zypper --ignore-unknown --non-interactive install --no-confirm --no-recommends --force xfsprogs


COPY . /out/

FROM scratch
COPY --from=build /out/ /
ENTRYPOINT [ "/make-rootfs" ]
