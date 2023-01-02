FROM lfedge/eve-suse:7d66f557e844047f0740535c5d5178af0f10be04 as kernel-build

ENV BUILD_PKGS argp-standalone automake bash bc binutils-dev bison build-base \
               diffutils flex git gmp-devel gnupg installkernel kmod \
               libelf-devel openssl-devel glibc-devel ncurses-devel python3 \
               sed squashfs-tools tar xz xz-dev zlib-devel libunwind-devel \
	       patch gcc gcc-c++
ENV BUILD_PKGS_arm64 uboot-tools
RUN eve-suse-deploy.sh

ENV XEN_UBOOT_ADDR 0x81000000
ENV XEN_VERSION 4.15.0
ENV XEN_SOURCE=https://downloads.xenproject.org/release/xen/${XEN_VERSION}/xen-${XEN_VERSION}.tar.gz

# Download and verify xen
#TODO: verify Xen
# hadolint ignore=DL3020
ADD ${XEN_SOURCE} /xen.tar.gz
RUN [ -f "$(basename ${XEN_SOURCE})" ] || tar --absolute-names -xz < /xen.tar.gz && mv "/xen-${XEN_VERSION}" /xen

WORKDIR /xen/xen
COPY *.patch arch /tmp/
RUN ls /tmp #* failes to patch
RUN cp /tmp/"$(uname -m)"/*.patch /tmp/
RUN for p in /tmp/*.patch ; do patch -p1 < "$p" || exit 1 ; done
RUN chmod +x scripts/* || :

RUN make defconfig && \
    make oldconfig && \
    rm -rf /out && mkdir -p /out/boot

RUN make -j "$(getconf _NPROCESSORS_ONLN)" && \
    case $(uname -m) in \
    x86_64) \
        cp xen.gz /out/boot/xen.gz \
    ;; \
    aarch64) \
        mkimage -A arm64 -T kernel -a $XEN_UBOOT_ADDR -e $XEN_UBOOT_ADDR -C none -d xen /out/boot/xen.uboot ;\
        cp xen.efi /out/boot/ \
        ;; \
    esac

FROM scratch
ENTRYPOINT []
CMD []
WORKDIR /boot
COPY --from=kernel-build /out/* .
