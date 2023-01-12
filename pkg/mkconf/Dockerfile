FROM lfedge/eve-suse:c30aba4558a5f755e2875f8cdf48c4e46d31a29f AS build

#* dosfstools already in SuSE busybox image
ENV PKGS mtools
RUN eve-suse-deploy.sh

COPY make-config /out/
RUN mkdir -p /out/conf/raw

FROM scratch
COPY --from=build /out /

WORKDIR /
ENTRYPOINT [ "/make-config" ]
