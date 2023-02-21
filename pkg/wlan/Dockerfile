FROM lfedge/eve-suse:8c48adb6dc81928dfc1016e2ee44c4b18cacbeb2 as build
ENV PKGS wireless-tools wpa_supplicant
RUN eve-suse-deploy.sh

FROM scratch
COPY --from=build /out/ /
COPY init.sh /init.sh

ENTRYPOINT []
CMD ["/init.sh"]
