FROM lfedge/eve-suse:2f1c38631c5199f885ef4ddde47108a7cb5e6e2d AS build

ENV BUILD_PKGS tar
ENV PKGS libarchive13 mtools xorriso
RUN eve-suse-deploy.sh

RUN echo "mtools_skip_check=1" >> /out/etc/mtools.conf

FROM scratch
COPY --from=build /out /
COPY . /
WORKDIR /
ENTRYPOINT [ "/make-efi" ]
