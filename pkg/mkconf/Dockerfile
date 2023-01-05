FROM lfedge/eve-suse:263a9793e6b21aae48083a653552bec245ee1a92 AS build

#* dosfstools already in SuSE busybox image
ENV PKGS mtools
RUN eve-suse-deploy.sh

COPY make-config /out/
RUN mkdir -p /out/conf/raw

FROM scratch
COPY --from=build /out /

WORKDIR /
ENTRYPOINT [ "/make-config" ]
