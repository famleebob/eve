FROM lfedge/eve-suse:2f1c38631c5199f885ef4ddde47108a7cb5e6e2d as build
ENV PKGS wireless-tools wpa_supplicant
RUN eve-suse-deploy.sh

FROM scratch
COPY --from=build /out/ /
COPY init.sh /init.sh

ENTRYPOINT []
CMD ["/init.sh"]
