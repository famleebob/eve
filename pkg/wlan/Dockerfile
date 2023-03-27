FROM lfedge/eve-suse:0e399fa0bfb2afbbe433313c3cd19b0e988ed80c as build
ENV PKGS wireless-tools wpa_supplicant
RUN eve-suse-deploy.sh

FROM scratch
COPY --from=build /out/ /
COPY init.sh /init.sh

ENTRYPOINT []
CMD ["/init.sh"]
