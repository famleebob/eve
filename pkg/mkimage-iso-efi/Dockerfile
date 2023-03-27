FROM lfedge/eve-suse:0e399fa0bfb2afbbe433313c3cd19b0e988ed80c AS build

ENV BUILD_PKGS tar mtools
ENV PKGS libarchive13 mtools xorriso binutils dosfstools libarchive-devel
RUN eve-suse-deploy.sh

RUN echo "mtools_skip_check=1" >> /out/etc/mtools.conf

FROM scratch
COPY --from=build /out /
COPY . /
WORKDIR /
ENTRYPOINT [ "/make-efi" ]
