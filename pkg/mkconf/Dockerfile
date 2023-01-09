FROM lfedge/eve-suse:2f1c38631c5199f885ef4ddde47108a7cb5e6e2d AS build

#* dosfstools already in SuSE busybox image
ENV PKGS mtools
RUN eve-suse-deploy.sh

COPY make-config /out/
RUN mkdir -p /out/conf/raw

FROM scratch
COPY --from=build /out /

WORKDIR /
ENTRYPOINT [ "/make-config" ]
