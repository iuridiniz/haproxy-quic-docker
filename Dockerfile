# Docker image that builds haproxy from source + openssl3 from quictls

FROM gcc:12-bookworm as openssl-quic-builder

# ignore these default arguments values, they are overridden by the build command with updated values.
ARG OPENSSL_URL=https://github.com/quictls/openssl/archive/refs/tags/openssl-3.0.10-quic1.tar.gz
ARG OPENSSL_SHA1SUM=f82ee600a914f572aa54a9fce1560bc66fad132c
ARG OPENSSL_OPTS="enable-tls1_3 \
    -g -O3 -fstack-protector-strong -Wformat -Werror=format-security \
    -DOPENSSL_TLS_SECURITY_LEVEL=2 -DOPENSSL_USE_NODELETE -DL_ENDIAN \
    -DOPENSSL_PIC -DOPENSSL_CPUID_OBJ -DOPENSSL_IA32_SSE2 \
    -DOPENSSL_BN_ASM_MONT -DOPENSSL_BN_ASM_MONT5 -DOPENSSL_BN_ASM_GF2m \
    -DSHA1_ASM -DSHA256_ASM -DSHA512_ASM -DKECCAK1600_ASM -DMD5_ASM \
    -DAESNI_ASM -DVPAES_ASM -DGHASH_ASM -DECP_NISTZ256_ASM -DX25519_ASM \
    -DX448_ASM -DPOLY1305_ASM -DNDEBUG -Wdate-time -D_FORTIFY_SOURCE=2 \
    "

# cache wget
RUN --mount=type=cache,target=/cache \
    mkdir -p /tmp/openssl /cache && \
    cd /tmp/openssl && \
    wget -c $OPENSSL_URL -O /cache/openssl-$OPENSSL_SHA1SUM.tar.gz && \
    echo "$OPENSSL_SHA1SUM  /cache/openssl-$OPENSSL_SHA1SUM.tar.gz" | sha1sum -c - || (rm -f /cache/openssl-$OPENSSL_SHA1SUM.tar.gz && exit 1) && \
    tar -xzf /cache/openssl-$OPENSSL_SHA1SUM.tar.gz && \
    cd openssl-* && \
    ./config --libdir=lib --prefix=/opt/quictls $OPENSSL_OPTS && \
    make -j $(nproc) && \
    make install -j $(nproc) && \
    cp /opt/quictls/lib/libcrypto.so /usr/lib/ && \
    cp /opt/quictls/lib/libssl.so /usr/lib/ && \
    ldconfig && \
    /opt/quictls/bin/openssl version -a && \
    cd / && \
    rm -rf /tmp/openssl

FROM gcc:12-bookworm as haproxy-builder

# ignore these default arguments values, they are overridden by the build command with updated values.
ARG HAPROXY_URL=http://www.haproxy.org/download/2.8/src/haproxy-2.8.2.tar.gz
ARG HAPROXY_SHA1SUM=63fec6a323b70fe4a45dc793a8956d756c13e516
ARG HAPROXY_CFLAGS="-O3 -g -Wall -Wextra -Wundef -Wdeclaration-after-statement -Wfatal-errors -Wtype-limits -Wshift-negative-value -Wshift-overflow=2 -Wduplicated-cond -Wnull-dereference -fwrapv -Wno-address-of-packed-member -Wno-unused-label -Wno-sign-compare -Wno-unused-parameter -Wno-clobbered -Wno-missing-field-initializers -Wno-cast-function-type -Wno-string-plus-int -Wno-atomic-alignment"
ARG HAPROXY_LDFLAGS=""
ARG HAPROXY_OPTS="TARGET=linux-glibc \
    USE_PCRE2=1 USE_PCRE2_JIT=1 \
    USE_PCRE= USE_PCRE_JIT= \
    USE_GETADDRINFO=1 \
    USE_OPENSSL=1 USE_LIBCRYPT=1 \
    USE_LUA=1 \
    USE_PROMEX=1 \
    USE_QUIC=1 \
    USE_EPOOL=1 \
    USE_THREAD=1 \
    USE_NS=1 \
    USE_SLZ=1 USE_ZLIB= \
    "

# install dependencies (lua, pcre2)
RUN apt-get update && apt-get install -y --no-install-recommends \
    libpcre2-dev \
    liblua5.3-dev \
    && rm -rf /var/lib/apt/lists/*

COPY --from=openssl-quic-builder /opt/quictls /opt/quictls
RUN \
    echo "/opt/quictls/lib" > /etc/ld.so.conf.d/quictls.conf && \
    ldconfig && \
    /opt/quictls/bin/openssl version -a

RUN --mount=type=cache,target=/cache \
    mkdir -p /tmp/haproxy /cache && \
    cd /tmp/haproxy && \
    wget -c $HAPROXY_URL -O /cache/haproxy-$HAPROXY_SHA1SUM.tar.gz && \
    echo "$HAPROXY_SHA1SUM  /cache/haproxy-$HAPROXY_SHA1SUM.tar.gz" | sha1sum -c - || (rm -f /cache/haproxy-$HAPROXY_SHA1SUM.tar.gz && exit 1) && \
    tar -xzf /cache/haproxy-$HAPROXY_SHA1SUM.tar.gz && \
    cd haproxy-* && \
    make -j $(nproc) $HAPROXY_OPTS CFLAGS="$HAPROXY_CFLAGS" LDFLAGS="$HAPROXY_LDFLAGS" SSL_INC=/opt/quictls/include SSL_LIB=/opt/quictls/lib all admin/halog/halog && \
    make -j $(nproc) install-bin  && \
    cp admin/halog/halog /usr/local/sbin/halog && \
    /usr/local/sbin/haproxy -vv && \
    cd / && \
    rm -rf /tmp/haproxy

FROM debian:12-slim as haproxy

# install dependencies (lua, pcre2)
RUN apt-get update && apt-get install -y --no-install-recommends \
    libpcre2-8-0 \
    libpcre2-posix3 \
    liblua5.3-0 \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

COPY --from=openssl-quic-builder /opt/quictls/lib /opt/quictls/lib
COPY --from=haproxy-builder /usr/local/sbin/haproxy /usr/local/sbin/haproxy
COPY --from=haproxy-builder /usr/local/sbin/halog /usr/local/sbin/halog

# make quicktls available
RUN \
    echo "/opt/quictls/lib" > /etc/ld.so.conf.d/quictls.conf && \
    ldconfig

# make some haproxy's directories
RUN \
    mkdir -p /etc/haproxy && \
    mkdir -p /etc/haproxy/errors && \
    mkdir -p /etc/haproxy/certs && \
    mkdir -p /var/lib/haproxy && \
    mkdir -p /var/run/haproxy && \
    /bin/true

# use haproxy as user and set permissions
RUN groupadd -r haproxy && \
    useradd -r -g haproxy haproxy && \
    chown -R haproxy:haproxy /var/lib/haproxy /var/run/haproxy

# add entrypoint
COPY ./scripts/docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod 755 /usr/local/bin/docker-entrypoint.sh
# add errors files
COPY ./errors /usr/local/etc/haproxy/errors
RUN chmod 644 /usr/local/etc/haproxy/errors/*

USER haproxy
RUN haproxy -vv

ENTRYPOINT [ "/usr/local/bin/docker-entrypoint.sh" ]
CMD [ "-W", "-db", "-f", "/etc/haproxy/haproxy.cfg" ]