FROM lfedge/eve-suse:c30aba4558a5f755e2875f8cdf48c4e46d31a29f AS build

ENV BUILD_PKGS tar mtools
ENV PKGS libarchive13 mtools xorriso
RUN eve-suse-deploy.sh

RUN echo "mtools_skip_check=1" >> /out/etc/mtools.conf

FROM scratch
COPY --from=build /out /
COPY . /
WORKDIR /
ENTRYPOINT [ "/make-efi" ]
