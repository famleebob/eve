FROM lfedge/eve-suse:6be054ed61f0d9d9d91f04cbfaef8c91ae606003 AS build

ENV PKGS mtools dosfstools
RUN eve-suse-deploy.sh

COPY make-config /out/
RUN mkdir -p /out/conf/raw

FROM scratch
COPY --from=build /out /

WORKDIR /
ENTRYPOINT [ "/make-config" ]
