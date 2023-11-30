FROM lfedge/eve-rhel:8c785ecb375912be79d40433553247b0a17b879e-dirty-91c7b8c AS build

ENV PKGS mtools dosfstools glibc-devel
RUN eve-rhel-deploy.sh

COPY make-config /out/
RUN mkdir -p /out/conf/raw

FROM scratch
COPY --from=build /out /

WORKDIR /
ENTRYPOINT [ "/make-config" ]
