FROM lfedge/eve-suse:c055c434cf56a79abfdb33f37e482f7c26efab9d AS build

ENV PKGS mtools dosfstools
RUN eve-suse-deploy.sh

COPY make-config /out/
RUN mkdir -p /out/conf/raw

FROM scratch
COPY --from=build /out /

WORKDIR /
ENTRYPOINT [ "/make-config" ]
