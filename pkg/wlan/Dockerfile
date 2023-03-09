FROM lfedge/eve-suse:4b46a3406cf79786e2e0aba3cdc60ed16aa20de2 as build
ENV PKGS wireless-tools wpa_supplicant
RUN eve-suse-deploy.sh

FROM scratch
COPY --from=build /out/ /
COPY init.sh /init.sh

ENTRYPOINT []
CMD ["/init.sh"]
