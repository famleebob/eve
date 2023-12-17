# syntax=docker/dockerfile-upstream:1.5.0-rc2-labs

FROM lfedge/eve-rhel:9ad685cd8abb440ce4c7101bf5f0a828f3a525dd-dirty-aa26ab2 as build
ENV BUILD_PKGS kernel-headers git gcc gcc-c++ perl-Pod-Checker \
               autoconf automake libtool make flex bison bash sed gettext \
               glibc-devel libstdc++-static diffutils perl-Pod-Html
RUN eve-rhel-deploy.sh

ADD https://gitlab.com/apparmor/apparmor.git#v3.1.4 /apparmor
WORKDIR /apparmor/libraries/libapparmor
RUN ./autogen.sh && \
    ./configure && \
    make

WORKDIR /apparmor/parser
RUN ../common/list_af_names.sh > base_af_names.h && \
    make

#Pull a selected set of artifacts into the final stage.
FROM scratch
COPY --from=build /out/ /
COPY --from=build /apparmor/parser/apparmor_parser /usr/bin/
COPY /etc/ /etc
COPY /profiles/* /etc/apparmor.d
COPY aa-init.sh /

WORKDIR /
ENTRYPOINT []
CMD ["/aa-init.sh"]
