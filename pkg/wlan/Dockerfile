FROM lfedge/eve-suse:586fbc00b49c6846ca6b5a79208698ed44ee952c as build
ENV PKGS wireless-tools wpa_supplicant
RUN eve-suse-deploy.sh

FROM scratch
COPY --from=build /out/ /
COPY init.sh /init.sh

ENTRYPOINT []
CMD ["/init.sh"]
