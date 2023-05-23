FROM lfedge/eve-suse:5b666917dbdbbbe9ccce73eead47f860ae96473c AS build

ENV BUILD_PKGS tar mtools
ENV PKGS libarchive13 mtools xorriso binutils dosfstools libarchive-devel
RUN eve-suse-deploy.sh

RUN echo "mtools_skip_check=1" >> /out/etc/mtools.conf

FROM scratch
COPY --from=build /out /
COPY . /
WORKDIR /
ENTRYPOINT [ "/make-efi" ]
