FROM lfedge/eve-suse:4b46a3406cf79786e2e0aba3cdc60ed16aa20de2 as build
ENV BUILD_PKGS cairo-devel openjpeg2-devel libjpeg8-devel libpng16-devel gcc make glibc-devel libopenssl-devel gcc file patch gawk libcairo2 nm
ENV PKGS libtasn1-progs p11-kit libcairo2 openjpeg2 libpng16-16 libvncserver
RUN eve-suse-deploy.sh

ENV GUACD_VERSION=1.0.0

ADD http://apache.org/dyn/closer.cgi?action=download&filename=guacamole/${GUACD_VERSION}/source/guacamole-server-${GUACD_VERSION}.tar.gz /${GUACD_VERSION}.tar.gz
ADD uuid-1.6.2.tar.gz /
COPY patches /patches

RUN find /usr/lib* -name libuuid\* -print | xargs rm -f
RUN cd /uuid-1.6.2 ; ./configure --prefix=/usr/ && make && make install

RUN tar xzvf ${GUACD_VERSION}.tar.gz ;\
    cd /guacamole-server-${GUACD_VERSION} ;\
    [ -d /patches/guacd-"${GUACD_VERSION}" ] && for patch in /patches/guacd-"${GUACD_VERSION}"/*.patch; do \
            echo "Applying $patch"; \
            patch -p1 < "$patch"; \
        done;\
    ./configure --prefix=/usr/ --with-vnc --disable-guacenc --disable-dependency-tracking && \
     make && make install
RUN ls /usr/lib64/libuuid*

FROM scratch

COPY --from=build /out/ /
COPY --from=build /usr/sbin/guacd /usr/sbin/guacd
COPY --from=build /usr/lib/libguac.so.* /usr/lib/libuuid.so.* /usr/lib/libguac-client-vnc* /usr/lib/

ENTRYPOINT []
CMD ["/usr/sbin/guacd", "-l", "4822", "-b", "0.0.0.0", "-L", "info", "-f"]
