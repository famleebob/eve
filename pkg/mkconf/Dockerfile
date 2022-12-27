FROM lfedge/eve-suse:c44c0bbfa6d2ecd892de235362d2c635c6475090 AS build

ENV PKGS mtools dosfstools
RUN eve-suse-deploy.sh

COPY make-config /out/
RUN mkdir -p /out/conf/raw

FROM scratch
COPY --from=build /out /

WORKDIR /
ENTRYPOINT [ "/make-config" ]
