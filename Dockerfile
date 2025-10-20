FROM golang:1.23.3-alpine3.20 AS builder

# Labels (best practice for OCI compliance)
LABEL org.opencontainers.image.title="wal-g" \
      org.opencontainers.image.description="Archival and restoration tool for PostgreSQL in the Cloud" \
      org.opencontainers.image.vendor="wal-g" \
      org.opencontainers.image.licenses="Apache-2.0" \
      org.opencontainers.image.source="https://github.com/wal-g/wal-g" \
      maintainer="https://github.com/codesshaman"

# Install build dependencies (CGO libs for compression/encryption features)
RUN apk add --no-cache \
    git \
    gcc \
    curl \
    make \
    cmake \
    lzo-dev \
    musl-dev \
    brotli-dev \
    libsodium-dev \
    linux-headers

# Set working directory
WORKDIR /go/src/wal-g

# Clone the repository (shallow clone for smaller layer)
RUN git clone --depth=1 --single-branch https://github.com/wal-g/wal-g.git .

# Enable optional features: Brotli compression, libsodium encryption, LZO decompression
ENV USE_BROTLI=1 \
    USE_LZO=1

# Download dependencies and build the Postgres binary
RUN make deps && make pg_build

# Runtime stage: Minimal Alpine image
FROM alpine:3.20

# Install runtime dependencies (certificates for HTTPS/S3, tzdata for timezones)
RUN apk add --no-cache \
    ca-certificates \
    tzdata \
    libstdc++ \
    && rm -rf /var/cache/apk/*

# Copy the built binary from builder stage
COPY --from=builder /go/src/wal-g/main/pg/wal-g /usr/local/bin/wal-g

# Ensure executable permissions
RUN chmod +x /usr/local/bin/wal-g

# Create non-root user for security (best practice)
RUN addgroup -g 1000 -S walg && \
    adduser -u 1000 -S walg -G walg
USER walg

# Set entrypoint to wal-g binary
ENTRYPOINT ["/usr/local/bin/wal-g"]

# Healthcheck (optional: checks if binary is executable)
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD ["/usr/local/bin/wal-g", "--version"] || exit 1
