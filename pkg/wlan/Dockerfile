FROM lfedge/eve-suse:8f41da0470c198d5da94d2d05eefebcaa72cd75a as build
ENV PKGS wireless-tools wpa_supplicant
RUN eve-suse-deploy.sh

FROM scratch
COPY --from=build /out/ /
COPY init.sh /init.sh

ENTRYPOINT []
CMD ["/init.sh"]
