FROM lfedge/eve-suse:6be054ed61f0d9d9d91f04cbfaef8c91ae606003 AS build

ENV BUILD_PKGS tar
ENV PKGS libarchive13 mtools \
         squashfs
RUN eve-suse-deploy.sh

COPY . /out/

FROM scratch
COPY --from=build /out/ /
ENTRYPOINT [ "/make-rootfs" ]
