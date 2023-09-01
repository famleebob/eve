FROM lfedge/eve-rhel:f44980896e5d50c64588fd998cc681762cb3df81-dirty-a1e5388 AS build

ENV PKGS mtools dosfstools
RUN eve-rhel-deploy.sh

COPY make-config /out/
RUN mkdir -p /out/conf/raw

FROM scratch
COPY --from=build /out /

WORKDIR /
ENTRYPOINT [ "/make-config" ]
