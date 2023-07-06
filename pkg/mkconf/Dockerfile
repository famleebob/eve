FROM lfedge/eve-suse:8f41da0470c198d5da94d2d05eefebcaa72cd75a AS build

ENV PKGS mtools dosfstools
RUN eve-suse-deploy.sh

COPY make-config /out/
RUN mkdir -p /out/conf/raw

FROM scratch
COPY --from=build /out /

WORKDIR /
ENTRYPOINT [ "/make-config" ]
