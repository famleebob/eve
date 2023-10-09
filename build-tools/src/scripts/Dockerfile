# syntax=docker/dockerfile-upstream:1.5.0-rc2-labs
FROM registry.access.redhat.com/ubi9/ubi

ARG GOVER=1.20.1
ARG BUILDARCH
ADD https://go.dev/dl/go${GOVER}.linux-${BUILDARCH}.tar.gz /go${GOVER}.tar.gz
#** no RHEL specific docker image of go available
#**   use ubi container, and install correct go version
RUN tar -C /usr/local -xzf /go${GOVER}.tar.gz
RUN cd /usr/bin && ln -s /usr/local/go/bin/go .
RUN cd /usr/bin && ln -s /usr/local/go/bin/gofmt .

ARG USER
ARG GROUP
ARG UID
ARG GID
# all_proxy is the standard proxy definer for socks proxies. Docker build only has built-ins for http_proxy,https_proxy,ftp_proxy,no_proxy
# so we need to declare it explicitly
# this must be an ARG so it doesn't carry through post-build phase
ARG all_proxy
# hadolint ignore=DL3018
RUN yum -y install openssh-clients git gcc kernel-headers glibc-devel \
           util-linux libpcap-devel bash vim make sudo tar curl \
           patch dnsmasq --allowerasing
# hadolint ignore=DL3018
RUN userdel ${USER} ; groupdel ${GROUP} || :
RUN sed -ie /:${UID}:/d /etc/passwd /etc/shadow ; sed -ie /:${GID}:/d /etc/group || :
RUN groupadd -g ${GID} ${GROUP} && useradd -d /home/${USER} -g ${GROUP} -M -u ${UID} ${USER}
RUN echo "${USER} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${USER}
# dep is deprecated and probably should be gotten rid of; no need to parametrize the version, as there will be no further releases
# hadolint ignore=SC2086,DL4006
#**RUN OS="$(uname -o | tr '[:upper:]' '[:lower:]')" && PLATFORM="$(go version | sed 's#^.*'${OS}'/##g')" && curl -o /usr/local/bin/dep -L "https://github.com/golang/dep/releases/download/v0.5.4/dep-${OS}-${PLATFORM}" && chmod +x /usr/local/bin/dep

RUN go install github.com/golang/protobuf/protoc-gen-go@v1.5.2
RUN go install gotest.tools/gotestsum@v1.7.0
RUN go install github.com/seamia/protodot@87817c3d0a8e7af753af15508b51292e941bc7c6

RUN mv /root/go/bin/protodot /usr/local/bin
RUN mv /root/go/bin/* /usr/bin
ENV HOME /home/${USER}
ENV GOFLAGS=-mod=vendor
ENV GO111MODULE=on
