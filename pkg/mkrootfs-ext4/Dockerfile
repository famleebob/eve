FROM lfedge/eve-suse:c30aba4558a5f755e2875f8cdf48c4e46d31a29f AS build

ENV BUILD_PKGS tar bsdtar
ENV PKGS libarchive13 mtools \
         squashfs bsdtar
RUN eve-suse-deploy.sh

COPY . /out/

FROM scratch
COPY --from=build /out/ /
ENTRYPOINT [ "/make-rootfs" ]
