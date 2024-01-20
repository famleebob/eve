# syntax=docker/dockerfile-upstream:1.5.0-rc2-labs
FROM lfedge/eve-rhel:c215632c87d22f89ab2d20aebe3d66462e793b20-dirty-aac5fba as build
ENV BUILD_PKGS automake autoconf gettext gettext-devel git pkgconfig \
               libtool glibc-devel kernel-headers gcc make glib2-devel \
               autoconf-archive patch cmake gtk-doc go binutils
ENV PKGS ppp jq glib2
RUN eve-rhel-deploy.sh

ENV LIBUBOX_COMMIT=7da66430de3fc235bfc6ebb0b85fb90ea246138d
ENV JSONC_COMMIT=ed54353d8478ccdb8296c33c675662d16d68b40d
ENV INOTIFY_TOOLS_COMMIT=3.20.11.0
ENV PICOCOM_COMMIT=1acf1ddabaf3576b4023c4f6f09c5a3e4b086fb8
ENV LIBQMI_COMMIT=1.30.8
ENV LIBMBIM_COMMIT=1.26.4

ENV PKG_CONFIG_PATH=/usr/lib/pkgconfig

ADD --keep-git-dir=true https://github.com/json-c/json-c.git#${JSONC_COMMIT} /json-c
WORKDIR /json-c
RUN ./autogen.sh && ./configure && make install

ADD --keep-git-dir=true https://git.openwrt.org/project/libubox.git#${LIBUBOX_COMMIT} /libubox
WORKDIR /libubox
RUN cmake . -DBUILD_LUA=OFF -DBUILD_EXAMPLES=OFF && \
          CFLAGS+="-I/usr/local/include" make -v install

ADD --keep-git-dir=true https://gitlab.freedesktop.org/mobile-broadband/libmbim.git#${LIBMBIM_COMMIT} /libmbim
WORKDIR /libmbim
COPY patches/libmbim/*.patch /tmp/patches/libmbim/
RUN for patch in /tmp/patches/libmbim/*.patch ; do patch -p1 < "$patch" ; done
RUN ./autogen.sh && ./configure --prefix=/usr && make -j "$(getconf _NPROCESSORS_ONLN)" && make install

ADD --keep-git-dir=true https://gitlab.freedesktop.org/mobile-broadband/libqmi.git#${LIBQMI_COMMIT} /libqmi
WORKDIR /libqmi
RUN ./autogen.sh --without-udev && ./configure --prefix=/usr --without-udev --enable-mbim-qmux && make -j "$(getconf _NPROCESSORS_ONLN)" && make install

ADD --keep-git-dir=true https://github.com/inotify-tools/inotify-tools.git#${INOTIFY_TOOLS_COMMIT} /inotify-tools
WORKDIR /inotify-tools
RUN ./autogen.sh && ./configure --prefix=/usr && make -j "$(getconf _NPROCESSORS_ONLN)" && make install

ADD --keep-git-dir=true https://github.com/npat-efault/picocom.git#${PICOCOM_COMMIT} /picocom
WORKDIR /picocom
# Need this patch to build with musl: https://github.com/npat-efault/picocom/commit/1acf1ddabaf3576b4023c4f6f09c5a3e4b086fb8
RUN make -j "$(getconf _NPROCESSORS_ONLN)" && strip picocom && cp picocom /usr/bin/

RUN strip /usr/bin/*cli /usr/libexec/*proxy /usr/lib64/libmbim*.so.* /usr/lib64/libqmi*.so.* /usr/lib64/libinotifytools*.so.*

COPY decryptpasswd /decryptpasswd
WORKDIR /decryptpasswd
RUN CGO_ENABLED=0 go build -ldflags="-s -w" -v

# second stage (new-ish Docker feature) for smaller image
FROM scratch

ENTRYPOINT []
WORKDIR /
COPY --from=build /out/ /
COPY --from=build /usr/bin/qmicli /usr/bin/mbimcli /usr/bin/inotify* /usr/bin/picocom /bin/
COPY --from=build /usr/lib/libmbim*.so.[0-9] /usr/lib/libqmi*.so.[0-9] /usr/lib/
COPY --from=build /usr/lib/libinotifytools*.so.[0-9] /usr/lib/
COPY --from=build /usr/libexec/*proxy /usr/libexec/
COPY --from=build /decryptpasswd/decryptpasswd /usr/bin/
COPY usr/ /usr/
COPY etc/ /etc/
CMD ["/usr/bin/wwan-init.sh"]
