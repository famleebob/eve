FROM lfedge/eve-suse:8c48adb6dc81928dfc1016e2ee44c4b18cacbeb2 AS build

ENV PKGS mtools dosfstools
RUN eve-suse-deploy.sh

COPY make-config /out/
RUN mkdir -p /out/conf/raw

FROM scratch
COPY --from=build /out /

WORKDIR /
ENTRYPOINT [ "/make-config" ]
