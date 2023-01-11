#!/bin/bash

set -e

SELF=`readlink -f "$0"`
BASEDIR=$( (cd -P "`dirname "$SELF"`/.." && pwd) )

ENVS_DIR=${ENVS_DIR:-"$BASEDIR/envs"}
VERSIONS=${VERSIONS:-$(ls -1 "$ENVS_DIR/latest" "$ENVS_DIR"/[1-9]*)}
IMAGE_NAME=${IMAGE_NAME:-"iuridiniz/haproxy"}

for VERSION in $VERSIONS; do
    VERSION=${VERSION%/}
    VERSION=${VERSION##*/}
    if [ ! -f "$ENVS_DIR/$VERSION" ]; then
        echo "No env file for $IMAGE_NAME:$VERSION in $ENVS_DIR/$VERSION"
        continue
    fi 
    echo "Building $IMAGE_NAME:$VERSION"

    # load defaults
    [ -f "$ENVS_DIR/default" ] && . "$ENVS_DIR/default"

    # load overrides
    . "$ENVS_DIR/$VERSION"

    if [ -z "$HAPROXY_URL" ] || [ -z "$HAPROXY_SHA1SUM" ]; then
        echo "Skipping $VERSION - no HAPROXY_URL or HAPROXY_SHA1SUM"
        continue
    fi
    (
        set -x
        docker build \
            -t "$IMAGE_NAME:$VERSION" \
            --build-arg HAPROXY_URL="$HAPROXY_URL" \
            --build-arg HAPROXY_SHA1SUM="$HAPROXY_SHA1SUM" \
            --build-arg HAPROXY_CFLAGS="$HAPROXY_CFLAGS" \
            --build-arg HAPROXY_LDFLAGS="$HAPROXY_LDFLAGS" \
            --build-arg OPENSSL_URL="$OPENSSL_URL" \
            --build-arg OPENSSL_SHA1SUM="$OPENSSL_SHA1SUM" \
            --build-arg OPENSSL_OPTS="$OPENSSL_OPTS" \
            "$BASEDIR"
    )
done
