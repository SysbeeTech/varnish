FROM debian:12.2-slim AS builder
MAINTAINER "branko@sysbee.net"

ARG TARGETARCH TARGETPLATFORM

# Install required utils
RUN apt-get update \
    && apt-get install -y curl git

# Install Cosign for verifying other packages
# renovate: datasource=github-release-attachments depName=sigstore/cosign versioning=semver
ARG COSIGN_VERSION=v2.2.1
RUN curl -O -L "https://github.com/sigstore/cosign/releases/download/${COSIGN_VERSION}/cosign_${COSIGN_VERSION#v}_${TARGETARCH}.deb" \
    && dpkg -i cosign_${COSIGN_VERSION#v}_${TARGETARCH}.deb

RUN mkdir -p /tmp/binaries

# Install SOPS
# renovate: datasource=github-release-attachments depName=getsops/sops versioning=semver
ARG SOPS_VERSION=v3.8.1
ARG SOPS_FILENAME="sops-${SOPS_VERSION}.linux.${TARGETARCH}"

RUN set -x \
    && curl -LO https://github.com/getsops/sops/releases/download/${SOPS_VERSION}/${SOPS_FILENAME}
RUN set -x \
    && echo "Verifying SOPS checksums file signatures..." \
    && curl -LO https://github.com/getsops/sops/releases/download/${SOPS_VERSION}/sops-${SOPS_VERSION}.checksums.txt \
    && curl -LO https://github.com/getsops/sops/releases/download/${SOPS_VERSION}/sops-${SOPS_VERSION}.checksums.pem \
    && curl -LO https://github.com/getsops/sops/releases/download/${SOPS_VERSION}/sops-${SOPS_VERSION}.checksums.sig \
    && cosign verify-blob "sops-${SOPS_VERSION}.checksums.txt" \
        --certificate "sops-${SOPS_VERSION}.checksums.pem" \
        --signature "sops-${SOPS_VERSION}.checksums.sig" \
        --certificate-identity-regexp=https://github.com/getsops \
        --certificate-oidc-issuer=https://token.actions.githubusercontent.com
RUN set -x \
    && echo "Verifying SOPS file integrity..." \
    && sha256sum -c sops-${SOPS_VERSION}.checksums.txt --ignore-missing
RUN set -x \
    && mv -v ${SOPS_FILENAME} /tmp/binaries/sops \
    && chmod +x /tmp/binaries/sops

FROM debian:12.2-slim
MAINTAINER "branko@sysbee.net"
LABEL org.opencontainers.image.source https://github.com/sysbeetech/kubeci
COPY --from=builder /tmp/binaries/ /usr/local/bin/
COPY --from=builder /root/.local/ /root/.local/
RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install --no-install-recommends -y awscli yamllint git curl ca-certificates openssl \
    && apt-get autoremove -y \
    && apt-get clean autoclean\
    && rm -rf /var/lib/apt/lists/*
