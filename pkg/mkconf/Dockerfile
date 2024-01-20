FROM lfedge/eve-rhel:c215632c87d22f89ab2d20aebe3d66462e793b20-dirty-aac5fba AS build

ENV PKGS mtools dosfstools glibc-devel
RUN eve-rhel-deploy.sh

COPY make-config /out/
RUN mkdir -p /out/conf/raw

FROM scratch
COPY --from=build /out /

WORKDIR /
ENTRYPOINT [ "/make-config" ]
