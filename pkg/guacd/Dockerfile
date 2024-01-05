# syntax=docker/dockerfile-upstream:1.5.0-rc2-labs
FROM lfedge/eve-rhel:9ad685cd8abb440ce4c7101bf5f0a828f3a525dd-dirty-0409384 as build
#** can't find libvncserver-devel in RHEL
ENV BUILD_PKGS cairo-devel libpng-devel libpng-devel gcc make glibc-devel \
               openssl-devel file patch patch cpp info git cmake \
               libjpeg-devel diffutils autoconf automake libuuid-devel
ENV PKGS glibc libtasn1-tools  p11-kit cairo libjpeg libpng libuuid net-tools \
         iproute
RUN eve-rhel-deploy.sh

ENV GUACD_VERSION=1.0.0
ENV LIBVVNC_VERSION=LibVNCServer-0.9.13

ADD http://apache.org/dyn/closer.cgi?action=download&filename=guacamole/${GUACD_VERSION}/source/guacamole-server-${GUACD_VERSION}.tar.gz /${GUACD_VERSION}.tar.gz
#* Use util-linux version of `libuuid`, conflictes with OSSP version (1.6.0)
#*  normally built for EVE.  Prevents link error with libfontconfig
#*  which wants a version specific symbol from libuuid (`uuid_copy@UUID_1.0`)
#** ADD uuid-1.6.2.tar.gz /

#** RUN cd /uuid-1.6.2 ; ./configure --prefix=/usr/ && make -j "$(getconf _NPROCESSORS_ONLN)" && make install

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
COPY patches /patches
RUN tar xzvf ${GUACD_VERSION}.tar.gz ;\
    cd /guacamole-server-${GUACD_VERSION} ;\
    [ -d /patches/guacd-"${GUACD_VERSION}" ] && for patch in /patches/guacd-"${GUACD_VERSION}"/*.patch; do \
            echo "Applying $patch"; \
            patch -p1 < "$patch"; \
        done;\
    touch aclocal.m4 Makefile.am Makefile.in && \
    autoconf && \ 
    ./configure --prefix=/usr/ --with-vnc --disable-guacenc --disable-dependency-tracking && \
     make -j "$(getconf _NPROCESSORS_ONLN)" && make install

FROM scratch

COPY --from=build /out/ /
COPY --from=build /usr/sbin/guacd /usr/sbin/guacd
COPY --from=build /usr/lib64/libguac.so.* /usr/lib64/libguac-client-vnc* /usr/lib64/
COPY --from=build /usr/local/lib64/libvncserver* /usr/local/lib64

ENTRYPOINT []
CMD ["/usr/sbin/guacd", "-l", "4822", "-b", "0.0.0.0", "-L", "debug", "-f"]
