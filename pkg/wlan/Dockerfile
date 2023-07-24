FROM lfedge/eve-suse:54c6e6238e27f66068f42fc0ef33e8b611a7b64d as build
ENV PKGS wireless-tools wpa_supplicant
RUN eve-suse-deploy.sh

FROM scratch
COPY --from=build /out/ /
COPY init.sh /init.sh

ENTRYPOINT []
CMD ["/init.sh"]
