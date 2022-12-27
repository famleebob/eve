FROM lfedge/eve-suse:c44c0bbfa6d2ecd892de235362d2c635c6475090 AS build

ENV BUILD_PKGS tar
ENV PKGS libarchive13 mtools xorriso
RUN eve-suse-deploy.sh

RUN echo "mtools_skip_check=1" >> /out/etc/mtools.conf

FROM scratch
COPY --from=build /out /
COPY . /
WORKDIR /
ENTRYPOINT [ "/make-efi" ]
