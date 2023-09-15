# syntax=docker/dockerfile-upstream:1.5.0-rc2-labs
FROM lfedge/eve-suse:54c6e6238e27f66068f42fc0ef33e8b611a7b64d as build
ENV BUILD_PKGS cairo-devel openjpeg2-devel libjpeg8-devel libpng16-devel \
               gcc make glibc-devel libopenssl-devel file patch gawk \
               libcairo2 binutils git cmake autoconf automake
#* libvncserver not provided by SuSE, build here
ENV PKGS libtasn1-progs p11-kit libcairo2 openjpeg2 libpng16-16 libopenssl1_1
RUN eve-suse-deploy.sh

ENV GUACD_VERSION=1.0.0
ENV LIBVVNC_VERSION=LibVNCServer-0.9.13

#* ADD http://apache.org/dyn/closer.cgi?action=download&filename=guacamole/${GUACD_VERSION}/source/guacamole-server-${GUACD_VERSION}.tar.gz /${GUACD_VERSION}.tar.gz
ADD http://apache.org/dyn/closer.cgi?action=download&filename=guacamole/${GUACD_VERSION}/source/guacamole-server-${GUACD_VERSION}.tar.gz /${GUACD_VERSION}.tar.gz
#* Use util-linux version of `libuuid`, conflictes with OSSP version (1.6.0)
#*  normally built for EVE.  Prevents link error with libfontconfig
#*  which wants a version specific symbol from libuuid (`uuid_copy@UUID_1.0`)
#* ADD uuid-1.6.2.tar.gz /
COPY patches /patches

#* RUN cd /uuid-1.6.2 ; ./configure --prefix=/usr/ && make && make install
#* build libvncserver
ADD --keep-git-dir=true https://github.com/LibVNC/libvncserver.git#${LIBVVNC_VERSION} /libvncserver
WORKDIR /libvncserver
RUN git checkout ${LIBVVNC_VERSION}
RUN mkdir build
RUN cd build && cmake .. && cmake --build . && make install
RUN mkdir -p /out/usr/local/lib64/pkgconfig
RUN cp /usr/local/lib64/libvnc* /out/usr/local/lib64
RUN cp /usr/local/lib64/pkgconfig/libvnc* \
           /out/usr/local/lib64/pkgconfig

WORKDIR /
RUN tar xzvf ${GUACD_VERSION}.tar.gz ;\
    cd /guacamole-server-${GUACD_VERSION} ;\
    [ -d /patches/guacd-"${GUACD_VERSION}" ] && for patch in /patches/guacd-"${GUACD_VERSION}"/*.patch; do \
            echo "Applying $patch"; \
            patch -p1 < "$patch"; \
        done;\
    autoconf && \
    ./configure --prefix=/usr/ --with-vnc --disable-guacenc --disable-dependency-tracking && \
     make && make install

FROM scratch

COPY --from=build /out/ /
COPY --from=build /usr/sbin/guacd /usr/sbin/guacd
COPY --from=build /usr/lib/libguac.so.* /usr/lib/libuuid.so.* /usr/lib/libguac-client-vnc* /usr/lib64/
COPY --from=build /usr/local/lib/libvncserver* /usr/local/lib64

ENTRYPOINT []
CMD ["/usr/sbin/guacd", "-l", "4822", "-b", "0.0.0.0", "-L", "info", "-f"]
