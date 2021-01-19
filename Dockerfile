# This Dockerfile extracts the source code and headers from linuxkit source image
# and build the perf in a ubuntu image

ARG KERNEL_VERSION=4.19.121
FROM linuxkit/kernel:$KERNEL_VERSION AS ksrc

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
    apt-get update && env DEBIAN_FRONTEND=noninteractive apt-get build-dep -y linux-tools-common && apt-get install -y gcc-8 libiberty-dev binutils-dev systemtap-sdt-dev liblzma-dev && \
    update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-8 10

ADD patch/linux-001-backport-tools-remove-gettid.patch /patchfile

RUN tar xf linux.tar.xz && \
    cd /linux && patch -p1 < /patchfile && \
    make -C tools perf_install prefix=/opt/perf && \
    rm -f /opt/perf/bin/trace && strip /opt/perf/bin/perf


FROM ubuntu:20.04 AS kheader
COPY --from=ksrc /kernel-dev.tar /
RUN cd / && tar xf kernel-dev.tar

FROM ubuntu:20.04
ARG KERNEL_VERSION
ENV KERNEL_VERSION=$KERNEL_VERSION

COPY --from=build /opt/perf/ /usr/local/
COPY --from=kheader /usr/src /usr/src/
RUN ln -s `which perf` /usr/local/bin/trace

ADD entrypoint.sh /

RUN apt-get update && apt-get install -y gawk libnuma1 binutils libpython2.7 libslang2 libunwind8 libdw1 sysstat bpfcc-tools bpftrace && \
    rm -rf /var/lib/apt/lists/* && apt-get clean

ENTRYPOINT ["/entrypoint.sh"]

