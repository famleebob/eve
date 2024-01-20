# syntax=docker/dockerfile-upstream:1.5.0-rc2-labs

FROM lfedge/eve-rhel:c215632c87d22f89ab2d20aebe3d66462e793b20-dirty-aac5fba as build
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
