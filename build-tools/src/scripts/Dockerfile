ARG GOVER=1.18.6
FROM registry.suse.com/bci/golang:1.18-16.43
ARG USER
ARG GROUP
ARG UID
ARG GID
# all_proxy is the standard proxy definer for socks proxies. Docker build only has built-ins for http_proxy,https_proxy,ftp_proxy,no_proxy
# so we need to declare it explicitly
# this must be an ARG so it doesn't carry through post-build phase
ARG all_proxy
# hadolint ignore=DL3018
RUN zypper install -y -l openssh-clients git gcc glibc-devel util-linux libpcap-devel bash vim make libprotobuf20 libprotobuf-c-devel sudo tar curl graphviz patch
# kernel-headers (linux-headers) comes from linux-glibc-devel
# ttf-freefonts => free-ttf-fonts, but can't find the package
# we need updated libraries, here we use the same version as for eve/alpine
# hadolint ignore=DL3018
RUN userdel ${USER} ; groupdel ${GROUP} || :
RUN zypper --non-interactive addrepo -r https://download.opensuse.org/repositories/filesystems/15.4/filesystems.repo -f -G
# had to disable gpg check wouldn't install, pilot error I'm sure
RUN zypper --non-interactive refresh
# RUN zypper --non-interactive install libnvpair1 zfs-devel libzfs4
# may need libzfs_core3 libzfsbootenv1
# was https://dl-cdn.alpinelinux.org/alpine/v3.16/main
# had to remove the -U --upgrade, does not exist in zypper
RUN sed -ie /:${UID}:/d /etc/passwd /etc/shadow ; sed -ie /:${GID}:/d /etc/group || :
RUN groupadd -g ${GID} ${GROUP} && useradd -d /home/${USER} -G ${GROUP} -M -u ${UID} ${USER}
RUN echo "${USER} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${USER}
# dep is deprecated and probably should be gotten rid of; no need to parametrize the version, as there will be no further releases
# hadolint ignore=SC2086,DL4006
RUN OS="$(uname -o | tr '[:upper:]' '[:lower:]' | sed -e 's/gnu\///')" && PLATFORM="$(go version | sed 's#^.*'${OS}'/##g')" && curl -o /usr/local/bin/dep -L "https://github.com/golang/dep/releases/download/v0.5.4/dep-${OS}-${PLATFORM}" && chmod +x /usr/local/bin/dep
RUN go install github.com/golang/protobuf/protoc-gen-go@v1.5.2
RUN go install gotest.tools/gotestsum@v1.7.0
RUN go install github.com/seamia/protodot@87817c3d0a8e7af753af15508b51292e941bc7c6
RUN mv /go/bin/protodot /usr/local/bin
RUN mv /go/bin/* /usr/bin
ENV HOME /home/${USER}
ENV GOFLAGS=-mod=vendor
ENV GO111MODULE=on
