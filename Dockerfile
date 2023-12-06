FROM varnish:7.4.2
MAINTAINER "branko@sysbee.net"
LABEL org.opencontainers.image.source https://github.com/sysbeetech/varnish

USER root

RUN apt-get update \
    && apt-get install --no-install-recommends -y prometheus-varnish-exporter procps \
    && apt-get autoremove -y \
    && apt-get clean autoclean\
    && rm -rf /var/lib/apt/lists/*

COPY scripts/shutdown-hook.sh /

USER varnish
