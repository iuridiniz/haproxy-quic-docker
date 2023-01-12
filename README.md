
# HAProxy + OpenSSL3 + QUIC (HTTP/3) Docker image

## HAProxy - The Reliable, High Performance TCP/HTTP Load Balancer

Almost copied from https://hub.docker.com/_/haproxy (DOCKER OFFICIAL IMAGE).

# Differences from official image (`haproxy:2.7`)
* Patched OpenSSL 3.X (QUIC APIs) from https://github.com/quictls/openssl (instead of openssl 1.x.y)
* HAProxy with:
   * QUIC (HTTP/3) enabled
   * ZLIB enabled
* Compiled with gcc-12 (instead of gcc-10)
  * `-O3` otimization

---------------
# Quick reference 

* Where to file issues:

   https://github.com/iuridiniz/haproxy-quic-docker/issues

* Dockerfile:

   https://github.com/iuridiniz/haproxy-quic-docker/blob/main/Dockerfile

# What is HAProxy?

HAProxy is a free, open source high availability solution, providing load balancing and proxying for TCP and HTTP-based applications by spreading requests across multiple servers. It is written in C and has a reputation for being fast and efficient (in terms of processor and memory usage).

# How to use this image

Since no two users of HAProxy are likely to configure it exactly alike, this image does not come with any default configuration.

Please refer to [upstream's excellent (and comprehensive) documentation on the subject of configuring HAProxy](http://docs.haproxy.org/) for your needs.

## Create a Dockerfile

```Dockerfile
FROM iuridiniz/haproxy:2.7
COPY haproxy.cfg /etc/haproxy/haproxy.cfg
```

## Build the container

```bash
$ docker build -t my-haproxy .
```

## Test the configuration file

```bash
$ docker run -it --rm --name haproxy-syntax-check my-haproxy haproxy -c -f /etc/haproxy/haproxy.cfg
````

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

