FROM lfedge/eve-suse:0e399fa0bfb2afbbe433313c3cd19b0e988ed80c as build
ENV BUILD_PKGS git go1.19
ENV PKGS iproute2 iptables
RUN eve-suse-deploy.sh

COPY src/  /edge-view/.
COPY go.mod /edge-view/.
COPY go.sum /edge-view/.
COPY vendor /edge-view/vendor
WORKDIR /edge-view

ENV CGO_ENABLED=0
SHELL ["/bin/bash", "-eo", "pipefail", "-c"]
# hadolint ignore=SC2046
RUN echo "Running go vet" && go vet ./... && echo "Running go fmt" && \
    ERR=$(gofmt -e -l -s $(find . -name \*.go | grep -v /vendor/)) && \
    if [ -n "$ERR" ] ; then echo "go fmt Failed - ERR: $ERR"; exit 1 ; fi

RUN GO111MODULE=on CGO_ENABLED=0 go build -ldflags "-s -w" -mod=vendor -o /out/usr/bin/edge-view . && cp edge-view-init.sh /out/usr/bin

FROM scratch
COPY --from=build /out/ /
RUN mkdir -p /tmp && echo "hosts: files dns" > /etc/nsswitch.conf

ENV PATH="/run/debug/usr/bin:${PATH}"

WORKDIR /
ENTRYPOINT ["/usr/bin/edge-view-init.sh"]
CMD []
