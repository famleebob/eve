FROM lfedge/eve-suse:7d66f557e844047f0740535c5d5178af0f10be04 AS build

ENV BUILD_PKGS tar
ENV PKGS libarchive13 mtools xorriso
RUN eve-suse-deploy.sh

RUN echo "mtools_skip_check=1" >> /out/etc/mtools.conf

FROM scratch
COPY --from=build /out /
COPY . /
WORKDIR /
ENTRYPOINT [ "/make-efi" ]
