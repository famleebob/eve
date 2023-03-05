FROM lfedge/eve-suse:1935168cce9da9d6664645f7dab27d23a7ab258e AS build

ENV BUILD_PKGS tar mtools
ENV PKGS libarchive13 mtools xorriso binutils dosfstools libarchive-devel
RUN eve-suse-deploy.sh

RUN echo "mtools_skip_check=1" >> /out/etc/mtools.conf

FROM scratch
COPY --from=build /out /
COPY . /
WORKDIR /
ENTRYPOINT [ "/make-efi" ]
