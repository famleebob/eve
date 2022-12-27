FROM lfedge/eve-suse:c44c0bbfa6d2ecd892de235362d2c635c6475090 as build
ENV BUILD_PKGS git go1.18
ENV PKGS coreutils
RUN eve-suse-deploy.sh

COPY ./  /newlog/.
WORKDIR /newlog

RUN GO111MODULE=on CGO_ENABLED=0 go build -ldflags "-s -w" -mod=vendor -o /out/usr/bin/newlogd ./cmd

# required for pubsub
RUN rm -rf /out/var/run && mkdir -p /out/run /out/var && ln -s /run /out/var

FROM scratch
COPY --from=build /out/ /
COPY newlogd-init.sh /newlogd-init.sh

WORKDIR /newlog
ENTRYPOINT []
CMD ["/newlogd-init.sh"]
