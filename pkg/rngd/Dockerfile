FROM lfedge/eve-suse:c055c434cf56a79abfdb33f37e482f7c26efab9d as build
ENV BUILD_PKGS go1.19 gcc glibc-devel-static
RUN eve-suse-deploy.sh

ENV GOPATH=/go PATH=$PATH:/go/bin

# see https://github.com/golang/go/issues/23672
ENV CGO_CFLAGS_ALLOW=(-mrdrnd|-mrdseed)

COPY cmd/rngd/ /go/src/rngd/
RUN GO111MODULE=auto REQUIRE_CGO=1 go-compile.sh /go/src/rngd

FROM scratch
ENTRYPOINT []
WORKDIR /
COPY --from=build /go/bin/rngd /sbin/rngd
CMD ["/sbin/rngd"]
