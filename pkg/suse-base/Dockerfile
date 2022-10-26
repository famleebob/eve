FROM registry.suse.com/bci/bci-busybox:latest AS builder
#*  we need to start here at some point; however,
#*   for now need to use the most primative SuSE
#*   BCI (Base Container Image) that includes `zypper`
#*   Will use that in `pkg/suse` for now ...

WORKDIR /rootfs

#* Need to understand what packages were installed in this
#*  root file system image, and add the tools needed
#*  For Now, this will be un-used for SuSE Base Distribution
#RUN tar --exclude="/proc" --exclude="/tmp/rootfs/tar.gz" --exclude="/tmp" --exclude="/rootfs" -czf /tmp/rootfs.tar.gz / || :
#RUN mv /tmp/rootfs.tar.gz /rootfs

# Since riscv64 is not officially supported yet, we use distinct package source
# busybox do not support https to storage.googleapis.com so we use http here
# and replace with https for repo url
#* used `$(docker run -d --platform linux/amd64 registry.suse.com/bci/bci-busybox:latest))`
#*  to generate the hash/name for the docker, that hash added to "fake" usl
#*  below
ARG ROOTFS_URL="https://build.opensuse.org/openSUSE:Factory/images/13b7a4ca10a6b81188c5eb0ff94a017785cec4cf68049c7093ec269da5764152-busybox-image"
#RUN touch /tmp/rootfs.tar.gz
#RUN wget -q -O /tmp/rootfs.tar.gz "$ROOTFS_URL"

#RUN case $(uname -m) in \
#    x86_64) \
#        ROOTFS_URL="https://build.opensuse.org/openSUSE:Factory/images/32ecb30fd10690cb1e08ed8b5b8cad1d-busybox-image" \
#        ;; \
#    aarch64|riscv64) \
##	echo "Assume only x86_64 for first attempt:Exiting" && exit 1 \
#        ;; \
#    *) echo "Unsupported architecture $(uname -m). Exiting" && exit 1 \
#      ;; \
#    esac && \
#    echo "$ROOTFS_URL" && \
#    wget -q -O /tmp/rootfs.tar.gz "$ROOTFS_URL" && \
#RUN    tar xzf /tmp/rootfs.tar.gz

#*  SuSE assume only amd64/x86_64 to simplify initial work
#*  - need to figure this out (SuSE support  for RISC-V is
#*    in development right now

FROM scratch
# seed the root filesystem
#COPY --from=builder /rootfs/ /

# set the defaults for docker run
ENV PATH /usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
CMD sh
