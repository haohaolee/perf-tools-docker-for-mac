# This Dockerfile extracts the source code and headers from a kernel package,
# builds the perf utility, and places it into a scratch image

FROM linuxkit/kernel:4.9.184 AS ksrc

FROM ubuntu:19.10 AS build

COPY --from=ksrc /linux.tar.xz /kernel-headers.tar /kernel-dev.tar /

RUN echo deb http://archive.ubuntu.com/ubuntu/ eoan main restricted > /etc/apt/sources.list && \
    echo deb-src http://archive.ubuntu.com/ubuntu/ eoan main restricted >> /etc/apt/sources.list && \
    echo deb http://archive.ubuntu.com/ubuntu/ eoan-updates main restricted >> /etc/apt/sources.list && \
    echo deb-src http://archive.ubuntu.com/ubuntu/ eoan-updates main restricted >> /etc/apt/sources.list && \
    echo deb http://archive.ubuntu.com/ubuntu/ eoan universe >> /etc/apt/sources.list && \
    echo deb-src http://archive.ubuntu.com/ubuntu/ eoan universe >> /etc/apt/sources.list && \
    echo deb http://archive.ubuntu.com/ubuntu/ eoan-updates universe >> /etc/apt/sources.list && \
    echo deb-src http://archive.ubuntu.com/ubuntu/ eoan-updates universe >> /etc/apt/sources.list && \
    echo deb http://archive.ubuntu.com/ubuntu/ eoan multiverse >> /etc/apt/sources.list && \
    echo deb-src http://archive.ubuntu.com/ubuntu/ eoan multiverse >> /etc/apt/sources.list && \
    echo deb http://archive.ubuntu.com/ubuntu/ eoan-updates multiverse >> /etc/apt/sources.list && \
    echo deb-src http://archive.ubuntu.com/ubuntu/ eoan-updates multiverse >> /etc/apt/sources.list && \
    echo deb http://archive.ubuntu.com/ubuntu/ eoan-backports main restricted universe multiverse >> /etc/apt/sources.list && \
    echo deb-src http://archive.ubuntu.com/ubuntu/ eoan-backports main restricted universe multiverse >> /etc/apt/sources.list && \
    echo deb http://security.ubuntu.com/ubuntu/ eoan-security main restricted >> /etc/apt/sources.list && \
    echo deb-src http://security.ubuntu.com/ubuntu/ eoan-security main restricted >> /etc/apt/sources.list && \
    echo deb http://security.ubuntu.com/ubuntu/ eoan-security universe >> /etc/apt/sources.list && \
    echo deb-src http://security.ubuntu.com/ubuntu/ eoan-security universe >> /etc/apt/sources.list && \
    echo deb http://security.ubuntu.com/ubuntu/ eoan-security multiverse >> /etc/apt/sources.list && \
    echo deb-src http://security.ubuntu.com/ubuntu/ eoan-security multiverse >> /etc/apt/sources.list && \
    apt-get update && env DEBIAN_FRONTEND=noninteractive apt-get build-dep -y linux-tools-common && apt-get install -y gcc-7 libiberty-dev binutils-dev systemtap-sdt-dev liblzma-dev && \
    update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-7 10

RUN tar xf linux.tar.xz && tar xf kernel-headers.tar && tar xf kernel-dev.tar && \
    cd /linux && make -C tools perf_install prefix=/opt/perf

FROM quay.io/iovisor/kubectl-trace-bpftrace:HEAD

RUN apt-get update && \
    apt-get install -y gawk libnuma1 binutils libpython2.7 libslang2 libunwind8 libdw1 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY --from=build /opt/perf/ /usr/local/
COPY --from=build /usr/src/ /usr/src/

ADD entrypoint.sh /

ENTRYPOINT ["/entrypoint.sh"]

