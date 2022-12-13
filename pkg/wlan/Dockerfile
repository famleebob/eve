FROM lfedge/eve-suse:6be054ed61f0d9d9d91f04cbfaef8c91ae606003 as build
ENV PKGS wireless-tools wpa_supplicant
RUN eve-suse-deploy.sh

FROM scratch
COPY --from=build /out/ /
COPY init.sh /init.sh

ENTRYPOINT []
CMD ["/init.sh"]
