FROM lfedge/eve-suse:c055c434cf56a79abfdb33f37e482f7c26efab9d AS build

ENV BUILD_PKGS tar mtools
ENV PKGS libarchive13 mtools xorriso binutils dosfstools libarchive-devel
RUN eve-suse-deploy.sh

RUN echo "mtools_skip_check=1" >> /out/etc/mtools.conf

FROM scratch
COPY --from=build /out /
COPY . /
WORKDIR /
ENTRYPOINT [ "/make-efi" ]
