# This Dockerfile extracts the source code and headers from linuxkit source image
# and build the perf in a ubuntu image

ARG KERNEL_VERSION=4.9.184
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
    apt-get update && env DEBIAN_FRONTEND=noninteractive apt-get build-dep -y linux-tools-common && apt-get install -y gcc-7 libiberty-dev binutils-dev systemtap-sdt-dev liblzma-dev && \
    update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-7 10

RUN tar xf linux.tar.xz && tar xf kernel-headers.tar && tar xf kernel-dev.tar && \
    cd /linux && make -C tools perf_install prefix=/opt/perf && \
    rm -f /opt/perf/bin/trace && strip /opt/perf/bin/perf

FROM ubuntu:19.10 AS bpftrace

RUN apt-get update && \
    apt-get install -y libbpfcc-dev bison cmake flex g++ git libelf-dev zlib1g-dev libfl-dev systemtap-sdt-dev && \
    apt-get install -y -y llvm-7-dev llvm-7-runtime libclang-7-dev clang-7 && \
    cd ~ && git clone https://github.com/iovisor/bpftrace && \
    mkdir bpftrace/build && cd bpftrace/build && \
    cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/opt/bpftrace .. && \
    make -j$(nproc) && make install

FROM ubuntu:19.10

RUN apt-get update && \
    apt-get install -y gawk libnuma1 binutils libpython2.7 libslang2 libunwind8 libdw1 libclang1-7 libbpfcc libllvm7 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY --from=build /opt/perf/ /usr/local/
RUN ln -s `which perf` /usr/local/bin/trace

COPY --from=build /usr/src/ /usr/src/

COPY --from=bpftrace /opt/bpftrace/ /usr/local/

ADD entrypoint.sh /

ENTRYPOINT ["/entrypoint.sh"]

