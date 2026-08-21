# syntax=docker/dockerfile:1
FROM --platform=$BUILDPLATFORM golang:1.26.3-alpine AS builder

ARG TARGETOS
ARG TARGETARCH

RUN apk update && apk add --no-cache make git openssl

WORKDIR /src
RUN git clone --depth 1 https://github.com/PasarGuard/node.git .
RUN go mod download

RUN CGO_ENABLED=0 GOOS=${TARGETOS} GOARCH=${TARGETARCH} make NAME=main build
RUN GOOS=${TARGETOS} GOARCH=${TARGETARCH} make install_xray

FROM alpine:latest

LABEL org.opencontainers.image.source="https://github.com/PasarGuard/node"

RUN apk update && apk add --no-cache wireguard-tools nftables iproute2 procps

WORKDIR /app
COPY --from=builder /src/main /app/main
COPY --from=builder /usr/local/bin/xray /usr/local/bin/xray
COPY --from=builder /usr/local/share/xray /usr/local/share/xray

ENV MODE_HOST=0.0.0.0
ENV SERVICE_PORT=62050

ENTRYPOINT ["/app/main"]
