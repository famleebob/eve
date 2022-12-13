FROM lfedge/eve-suse:6be054ed61f0d9d9d91f04cbfaef8c91ae606003 AS build

ENV BUILD_PKGS tar
ENV PKGS libarchive13 mtools xorriso
RUN eve-suse-deploy.sh

RUN echo "mtools_skip_check=1" >> /out/etc/mtools.conf

FROM scratch
COPY --from=build /out /
COPY . /
WORKDIR /
ENTRYPOINT [ "/make-efi" ]
