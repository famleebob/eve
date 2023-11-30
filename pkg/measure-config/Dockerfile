FROM lfedge/eve-rhel:8c785ecb375912be79d40433553247b0a17b879e-dirty-91c7b8c as build
ENV BUILD_PKGS git go
#** ENV PKGS alpine-baselayout musl-utils
RUN eve-rhel-deploy.sh

COPY src/  /measure-config/.
COPY go.mod /measure-config/.
COPY go.sum /measure-config/.
COPY vendor /measure-config/vendor
ARG GOPKGVERSION

WORKDIR /measure-config

ENV CGO_ENABLED=0
#** neither ash nor dash are found in RHEL packages, at least after 4
#** SHELL ["/bin/ash", "-eo", "pipefail", "-c"]
SHELL ["/bin/bash", "-eo", "pipefail", "-c"]
# hadolint ignore=SC2046
RUN echo "Running go vet" && go vet ./... && echo "Running go fmt" && \
    ERR=$(gofmt -e -l -s $(find . -name \*.go | grep -v /vendor/)) && \
    if [ -n "$ERR" ] ; then echo "go fmt Failed - ERR: $ERR"; exit 1 ; fi

RUN GO111MODULE=on CGO_ENABLED=0 go build -ldflags "-s -w -X=main.Version=${GOPKGVERSION}" -mod=vendor -o /out/usr/bin/measure-config .

FROM scratch
COPY --from=build /out/ /

WORKDIR /
ENTRYPOINT ["/usr/bin/measure-config"]
CMD []
