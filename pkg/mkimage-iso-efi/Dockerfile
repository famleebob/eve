FROM lfedge/eve-rhel:fd11ea87f91a90596f75c4f2aba61b13704f7fa0-dirty-399c4aa AS build

#** bsdcpio can't be found (for libarchive-tools replacement)
ENV PKGS dosfstools bsdtar binutils mtools xorriso glibc-gconv-extra
RUN eve-rhel-deploy.sh

RUN echo "mtools_skip_check=1" >> /out/etc/mtools.conf

FROM scratch
COPY --from=build /out /
COPY . /
WORKDIR /
ENTRYPOINT [ "/make-efi" ]
