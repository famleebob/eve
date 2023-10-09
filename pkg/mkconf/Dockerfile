FROM lfedge/eve-rhel:fd11ea87f91a90596f75c4f2aba61b13704f7fa0-dirty-399c4aa AS build

ENV PKGS mtools dosfstools glibc-devel
RUN eve-rhel-deploy.sh

COPY make-config /out/
RUN mkdir -p /out/conf/raw

FROM scratch
COPY --from=build /out /

WORKDIR /
ENTRYPOINT [ "/make-config" ]
