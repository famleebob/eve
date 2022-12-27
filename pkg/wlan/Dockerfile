FROM lfedge/eve-suse:c44c0bbfa6d2ecd892de235362d2c635c6475090 as build
ENV PKGS wireless-tools wpa_supplicant
RUN eve-suse-deploy.sh

FROM scratch
COPY --from=build /out/ /
COPY init.sh /init.sh

ENTRYPOINT []
CMD ["/init.sh"]
