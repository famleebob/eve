FROM registry.suse.com/bci/bci-busybox:latest AS builder
WORKDIR /rootfs

# Since riscv64 is not officially supported yet, we use distinct package source
# busybox do not support https to storage.googleapis.com so we use http here
# and replace with https for repo url
RUN case $(uname -m) in \
    x86_64) \
        ROOTFS_URL="https://build.opensuse.org/openSUSE:Factory/images/32ecb30fd10690cb1e08ed8b5b8cad1d-busybox-image" \
        ;; \
    aarch64|riscv64) \
	echo "Assume only x86_64 for first attempt:Exiting" && exit 1 \
#        ROOT_URL=http://storage.googleapis.com/eve-alpine && \
#        ROOTFS_URL="$ROOT_URL/images/alpine-minirootfs-220909-riscv64.tar.gz"; \
        ;; \
    *) echo "Unsupported architecture $(uname -m). Exiting" && exit 1 \
      ;; \
    esac && \
    wget -q -O /tmp/rootfs.tar.gz "$ROOTFS_URL" && \
    tar xzf /tmp/rootfs.tar.gz && \
#*  SuSE assume only amd64/x86_64 to simplify initial work
#*  - need to figure this out (SuSE support  for RISC-V is
#*    in development right now
#    if [ "$(uname -m)" = "riscv64" ] ; then \
#        wget -q -P etc/apk/keys \
#            "$ROOT_URL/keys/builder@projecteve.dev-62fe6660.rsa.pub" && \
#        ROOT_URL=https://storage.googleapis.com/eve-alpine && \
#        echo "$ROOT_URL/v3.16/main" > etc/apk/repositories && \
#        echo "$ROOT_URL/v3.16/community" >> etc/apk/repositories && \
#        echo "$ROOT_URL" > etc/apk/cache.url; \
#    fi

FROM scratch

# seed the root filesystem
COPY --from=builder /rootfs/ /

# set the defaults for docker run
ENV PATH /usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
CMD sh
