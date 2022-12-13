#
# StrongSwan VPN + Alpine Linux
#

FROM lfedge/eve-suse:586fbc00b49c6846ca6b5a79208698ed44ee952c as build
ENV BUILD_PKGS make patch gawk gcc glibc-devel tar iptables iproute2 openssl libopenssl-devel tar bzip binutils
RUN eve-suse-deploy.sh

ENV STRONGSWAN_VERSION 5.6.3
ENV STRONGSWAN_FILE strongswan-${STRONGSWAN_VERSION}.tar.bz2
ENV STRONGSWAN_RELEASE https://download.strongswan.org/${STRONGSWAN_FILE}
ENV CONFIGURE_OPTS_x86_64 --enable-aesni
ENV CONFIGURE_OPTS --prefix=/usr \
            --sysconfdir=/etc \
            --libexecdir=/usr/lib \
            --with-ipsecdir=/usr/lib/strongswan \
            --enable-chapoly \
            --enable-cmd \
            --enable-curl \
            --disable-dhcp \
            --enable-eap-dynamic \
            --enable-eap-identity \
            --enable-eap-md5 \
            --enable-eap-mschapv2 \
            --enable-eap-radius \
            --enable-eap-tls \
            --disable-farp \
            --enable-files \
            --enable-gcm \
            --enable-md4 \
            --enable-newhope \
            --enable-ntru \
            --enable-openssl \
            --enable-sha3 \
            --enable-shared \
            --enable-aes \
            --disable-des \
            --disable-gmp \
            --disable-hmac \
            --enable-ikev1 \
            --disable-md5 \
            --disable-rc2 \
            --enable-sha1 \
            --enable-sha2 \
            --disable-static

WORKDIR /tmp/strongswan
RUN rm -rf /out && mkdir /out

# FIXME: two reasons to build it instead of using the
# stock one:
#    1. alpine 3.6+ now has a conflict with libressl for curl-dev
#    2. linuxkit alpine image doesn't have curl-dev (because of #1?)
#* still valid with SuSE or can we just install libcurl-devel?
COPY curl-7.61.1.tar.bz2 /tmp/curl-7.61.1.tar.bz2
RUN tar -C /tmp -xjvf /tmp/curl-7.61.1.tar.bz2 ; cd /tmp/curl-7.61.1 ; ./configure --prefix=/usr ; make  -j "$(getconf _NPROCESSORS_ONLN)" install

COPY ${STRONGSWAN_FILE} /tmp/strongswan/strongswan.tar.bz2
RUN  tar --strip-components=1 -C /tmp/strongswan -xjf /tmp/strongswan/strongswan.tar.bz2
RUN  eval ./configure $CONFIGURE_OPTS \$CONFIGURE_OPTS_`uname -m`
RUN    make  -j "$(getconf _NPROCESSORS_ONLN)"
RUN    make install DESTDIR=/out

FROM scratch
ENTRYPOINT []
CMD []
WORKDIR /

COPY --from=build /out ./
