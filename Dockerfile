FROM golang:1-alpine AS build

ARG VERSION="0.16.0"
ARG CHECKSUM="331a70b446e08aaf8030501c8da24b5af35d95026e9c9c5e9fda32ff38183af0"

ADD https://github.com/prometheus/graphite_exporter/archive/v$VERSION.tar.gz /tmp/graphite_exporter.tar.gz

RUN [ "$(sha256sum /tmp/graphite_exporter.tar.gz | awk '{print $1}')" = "$CHECKSUM" ] && \
    apk add curl make && \
    tar -C /tmp -xf /tmp/graphite_exporter.tar.gz && \
    mkdir -p /go/src/github.com/prometheus && \
    mv /tmp/graphite_exporter-$VERSION /go/src/github.com/prometheus/graphite_exporter && \
    cd /go/src/github.com/prometheus/graphite_exporter && \
      make build

RUN mkdir -p /rootfs/bin && \
      cp /go/src/github.com/prometheus/graphite_exporter/graphite_exporter /rootfs/bin/ && \
    mkdir -p /rootfs/etc && \
      echo "nogroup:*:10000:nobody" > /rootfs/etc/group && \
      echo "nobody:*:10000:10000:::" > /rootfs/etc/passwd


FROM scratch

COPY --from=build --chown=10000:10000 /rootfs /

USER 10000:10000
EXPOSE 9108/tcp 9109/tcp 9109/udp
ENTRYPOINT ["/bin/graphite_exporter"]
