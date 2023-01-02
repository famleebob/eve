FROM lfedge/eve-suse:7d66f557e844047f0740535c5d5178af0f10be04 as build
ENV BUILD_PKGS git go1.19
#ENV PKGS Ialpine-baselayout musl-utils
RUN eve-suse-deploy.sh

COPY src/  /measure-config/.
COPY go.mod /measure-config/.
COPY go.sum /measure-config/.
COPY vendor /measure-config/vendor

WORKDIR /measure-config

ENV CGO_ENABLED=0
SHELL ["/bin/bash", "-eo", "pipefail", "-c"]
# hadolint ignore=SC2046
RUN echo "Running go vet" && go vet ./... && echo "Running go fmt" && \
    ERR=$(gofmt -e -l -s $(find . -name \*.go | grep -v /vendor/)) && \
    if [ -n "$ERR" ] ; then echo "go fmt Failed - ERR: $ERR"; exit 1 ; fi

RUN GO111MODULE=on CGO_ENABLED=0 go build -ldflags "-s -w" -mod=vendor -o /out/usr/bin/measure-config .

FROM scratch
COPY --from=build /out/ /

WORKDIR /
ENTRYPOINT ["/usr/bin/measure-config"]
CMD []
