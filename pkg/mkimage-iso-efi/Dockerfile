FROM lfedge/eve-suse:263a9793e6b21aae48083a653552bec245ee1a92 AS build

ENV BUILD_PKGS tar
ENV PKGS libarchive13 mtools xorriso
RUN eve-suse-deploy.sh

RUN echo "mtools_skip_check=1" >> /out/etc/mtools.conf

FROM scratch
COPY --from=build /out /
COPY . /
WORKDIR /
ENTRYPOINT [ "/make-efi" ]
