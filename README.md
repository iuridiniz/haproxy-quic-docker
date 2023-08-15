
# HAProxy + OpenSSL3 + QUIC (HTTP/3) Docker image

## HAProxy - The Reliable, High Performance TCP/HTTP Load Balancer

Almost copied from https://hub.docker.com/_/haproxy (DOCKER OFFICIAL IMAGE).

# Differences from official image (`haproxy:2.8`)
* Patched OpenSSL 3.X (QUIC APIs) from https://github.com/quictls/openssl (instead of openssl 1.x.y)
* HAProxy with:
   * QUIC (HTTP/3) enabled
* Compiled with gcc-13 (instead of gcc-10)
  * `-O3` optimization

---------------
# Quick reference 

* Where to file issues:

   https://github.com/iuridiniz/haproxy-quic-docker/issues

* Dockerfile:

   https://github.com/iuridiniz/haproxy-quic-docker/blob/main/Dockerfile

## `haproxy -vv`

```
docker run --rm -it iuridiniz/haproxy:2.8.2 -vv

HAProxy version 2.8.2-61a0f57 2023/08/09 - https://haproxy.org/
Status: long-term supported branch - will stop receiving fixes around Q2 2028.
Known bugs: http://www.haproxy.org/bugs/bugs-2.8.2.html
Running on: Linux 5.15.0-78-generic #85-Ubuntu SMP Fri Jul 7 15:25:09 UTC 2023 x86_64
Build options :
  TARGET  = linux-glibc
  CPU     = generic
  CC      = cc
  CFLAGS  = -O3 -g -Wall -Wextra -Wundef -Wdeclaration-after-statement -Wfatal-errors -Wtype-limits -Wshift-negative-value -Wshift-overflow=2 -Wduplicated-cond -Wnull-dereference -fwrapv -Wno-address-of-packed-member -Wno-unused-label -Wno-sign-compare -Wno-unused-parameter -Wno-clobbered -Wno-missing-field-initializers -Wno-cast-function-type -Wno-string-plus-int -Wno-atomic-alignment
  OPTIONS = USE_THREAD=1 USE_LIBCRYPT=1 USE_GETADDRINFO=1 USE_OPENSSL=1 USE_LUA=1 USE_ZLIB= USE_SLZ=1 USE_NS=1 USE_QUIC=1 USE_PROMEX=1 USE_PCRE= USE_PCRE_JIT= USE_PCRE2=1 USE_PCRE2_JIT=1
  DEBUG   = -DDEBUG_STRICT -DDEBUG_MEMORY_POOLS

Feature list : -51DEGREES +ACCEPT4 +BACKTRACE -CLOSEFROM +CPU_AFFINITY +CRYPT_H -DEVICEATLAS +DL -ENGINE +EPOLL -EVPORTS +GETADDRINFO -KQUEUE -LIBATOMIC +LIBCRYPT +LINUX_SPLICE +LINUX_TPROXY +LUA +MATH -MEMORY_PROFILING +NETFILTER +NS -OBSOLETE_LINKER +OPENSSL -OPENSSL_WOLFSSL -OT -PCRE +PCRE2 +PCRE2_JIT -PCRE_JIT +POLL +PRCTL -PROCCTL +PROMEX -PTHREAD_EMULATION +QUIC +RT +SHM_OPEN +SLZ +SSL -STATIC_PCRE -STATIC_PCRE2 -SYSTEMD +TFO +THREAD +THREAD_DUMP +TPROXY -WURFL -ZLIB

Default settings :
  bufsize = 16384, maxrewrite = 1024, maxpollevents = 200

Built with multi-threading support (MAX_TGROUPS=16, MAX_THREADS=256, default=16).
Built with OpenSSL version : OpenSSL 3.0.10+quic 1 Aug 2023
Running on OpenSSL version : OpenSSL 3.0.10+quic 1 Aug 2023
OpenSSL library supports TLS extensions : yes
OpenSSL library supports SNI : yes
OpenSSL library supports : TLSv1.0 TLSv1.1 TLSv1.2 TLSv1.3
OpenSSL providers loaded : default
Built with Lua version : Lua 5.3.6
Built with the Prometheus exporter as a service
Built with network namespace support.
Built with libslz for stateless compression.
Compression algorithms supported : identity("identity"), deflate("deflate"), raw-deflate("deflate"), gzip("gzip")
Built with transparent proxy support using: IP_TRANSPARENT IPV6_TRANSPARENT IP_FREEBIND
Built with PCRE2 version : 10.42 2022-12-11
PCRE2 library supports JIT : yes
Encrypted password support via crypt(3): yes
Built with gcc compiler version 12.3.0

Available polling systems :
      epoll : pref=300,  test result OK
       poll : pref=200,  test result OK
     select : pref=150,  test result OK
Total: 3 (3 usable), will use epoll.

Available multiplexer protocols :
(protocols marked as <default> cannot be specified using 'proto' keyword)
       quic : mode=HTTP  side=FE     mux=QUIC  flags=HTX|NO_UPG|FRAMED
         h2 : mode=HTTP  side=FE|BE  mux=H2    flags=HTX|HOL_RISK|NO_UPG
       fcgi : mode=HTTP  side=BE     mux=FCGI  flags=HTX|HOL_RISK|NO_UPG
  <default> : mode=HTTP  side=FE|BE  mux=H1    flags=HTX
         h1 : mode=HTTP  side=FE|BE  mux=H1    flags=HTX|NO_UPG
  <default> : mode=TCP   side=FE|BE  mux=PASS  flags=
       none : mode=TCP   side=FE|BE  mux=PASS  flags=NO_UPG

Available services : prometheus-exporter
Available filters :
        [BWLIM] bwlim-in
        [BWLIM] bwlim-out
        [CACHE] cache
        [COMP] compression
        [FCGI] fcgi-app
        [SPOE] spoe
        [TRACE] trace
```

# What is HAProxy?

HAProxy is a free, open source high availability solution, providing load balancing and proxying for TCP and HTTP-based applications by spreading requests across multiple servers. It is written in C and has a reputation for being fast and efficient (in terms of processor and memory usage).

# How to use this image

Since no two users of HAProxy are likely to configure it exactly alike, this image does not come with any default configuration.

Please refer to [upstream's excellent (and comprehensive) documentation on the subject of configuring HAProxy](http://docs.haproxy.org/) for your needs.

## Create a Dockerfile

```Dockerfile
FROM iuridiniz/haproxy:2.8
COPY haproxy.cfg /etc/haproxy/haproxy.cfg
```

## Build the container

```bash
$ docker build -t my-haproxy .
```

## Test the configuration file

```bash
$ docker run -it --rm --name haproxy-syntax-check my-haproxy haproxy -c -f /etc/haproxy/haproxy.cfg
```

## Run the container

```bash
$ docker run -d --name my-running-haproxy --sysctl net.ipv4.ip_unprivileged_port_start=0 my-haproxy
```

You will need a kernel at version 4.11 or newer to use `--sysctl net.ipv4.ip_unprivileged_port_start=0` , you may need to publish the ports your HAProxy is listening on to the host by specifying the `-p`option, for example `-p 8080:80` to publish port 8080 from the container host to port 80 in the container. Make sure the port you're using is free.

**Note**: This containers will run with a unprivileged user named `haproxy` by default (hence the `--sysctl net.ipv4.ip_unprivileged_port_start=0` above). **It's not recommended**, but if you want to run with a different user like `root`, just use `--user root`.

## Reloading config

If you used a bind mount for the config and have edited your haproxy.cfg file, you can use HAProxy's graceful reload feature by sending a SIGHUP to the container:

```bash
$ docker kill -s HUP my-running-haproxy
```

See [Stopping and restarting HAProxy](http://www.haproxy.org/download/2.7/doc/management.txt).

## Sample config for QUIC (HTTP/3)

```bash
frontend mysite
  bind :80
  bind :443  ssl crt /etc/haproxy/certs/foo.com/cert.pem alpn h2

  # enables HTTP/3 over QUIC
  bind quic4@:443 ssl crt /etc/haproxy/certs/foo.com/cert.pem alpn h3

  # Redirects to HTTPS
  http-request redirect scheme https unless { ssl_fc }

  # 'Alt-Svc' header invites client to switch to the QUIC protocol
  # Max age (ma) is set to 15 minutes (900 seconds), but
  # can be increased once verified working as expected
  http-response set-header alt-svc "h3=\":443\";ma=900;"

  default_backend webservers
```

See [Announcing HAProxy 2.6
](https://www.haproxy.com/blog/announcing-haproxy-2-6/).

# License

As with all Docker images, these likely contains many softwares with different licenses along with any direct or indirect dependencies of the primary software being contained.

The HAProxy license could be find [here](https://www.haproxy.org/download/1.3/doc/LICENSE).

# Alternatives

haproxytech images:
* [haproxytech/haproxy-docker-alpine-quic](https://github.com/haproxytech/haproxy-docker-alpine-quic)
* [haproxytech/haproxy-docker-ubuntu-quic](https://github.com/haproxytech/haproxy-docker-ubuntu-quic)
* [haproxytech/haproxy-docker-debian-quic](https://github.com/haproxytech/haproxy-docker-debian-quic)