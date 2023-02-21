FROM lfedge/eve-suse:8c48adb6dc81928dfc1016e2ee44c4b18cacbeb2 AS build

ENV BUILD_PKGS tar mtools
ENV PKGS libarchive13 mtools xorriso binutils dosfstools libarchive-devel
RUN eve-suse-deploy.sh

RUN echo "mtools_skip_check=1" >> /out/etc/mtools.conf

FROM scratch
COPY --from=build /out /
COPY . /
WORKDIR /
ENTRYPOINT [ "/make-efi" ]
