FROM lfedge/eve-rhel:c215632c87d22f89ab2d20aebe3d66462e793b20-dirty-aac5fba as build
ENV BUILD_PKGS make gcc kernel-headers patch
ENV PKGS wpa_supplicant iproute
RUN eve-rhel-deploy.sh

ENV WT_VER 30.pre9
ENV WT_SRCS https://hewlettpackard.github.io/wireless-tools/wireless_tools.${WT_VER}.tar.gz

ADD ${WT_SRCS} /wireless_tools.${WT_VER}.tar.gz
WORKDIR /
RUN tar xzf /wireless_tools.${WT_VER}.tar.gz
COPY flags.patch /wireless_tools.30
RUN cd /wireless_tools.30 && patch -p1 < flags.patch && \
                              make INSTALL_DIR=/out/usr/sbin \
                                   INSTALL_LIB=/out/usr/lib64 \
                                   INSTALL_INC=/out/usr/include \
                                   install
FROM scratch
COPY --from=build /out/ /
COPY init.sh /init.sh

ENTRYPOINT []
CMD ["/init.sh"]
