FROM lfedge/eve-suse:8f41da0470c198d5da94d2d05eefebcaa72cd75a as build
ENV BUILD_PKGS git go1.19
ENV PKGS coreutils
RUN eve-suse-deploy.sh

COPY ./  /newlog/.
WORKDIR /newlog

RUN df .

RUN GO111MODULE=on CGO_ENABLED=0 go build -ldflags "-s -w" -mod=vendor -o /out/usr/bin/newlogd ./cmd

# required for pubsub
RUN rm -rf /out/var/run && mkdir -p /out/run /out/var && ln -s /run /out/var

FROM scratch
COPY --from=build /out/ /
COPY newlogd-init.sh /newlogd-init.sh

WORKDIR /newlog
ENTRYPOINT []
CMD ["/newlogd-init.sh"]
