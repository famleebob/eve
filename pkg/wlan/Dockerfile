FROM lfedge/eve-suse:5b666917dbdbbbe9ccce73eead47f860ae96473c as build
ENV PKGS wireless-tools wpa_supplicant
RUN eve-suse-deploy.sh

FROM scratch
COPY --from=build /out/ /
COPY init.sh /init.sh

ENTRYPOINT []
CMD ["/init.sh"]
