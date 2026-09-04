# syntax=docker/dockerfile:1.7

ARG PYTHON_VERSION=3.11
ARG CLOUDBOT_VERSION=1.4.0
ARG CLOUDBOT_COMMIT=d891d49254d5c95ddd997c0d44e03a502966ba34

FROM python:${PYTHON_VERSION}-slim-bookworm AS builder
ARG CLOUDBOT_COMMIT

ENV PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PIP_NO_CACHE_DIR=1 \
    VIRTUAL_ENV=/opt/cloudbot/venv

RUN apt-get update \
    && apt-get install --yes --no-install-recommends ca-certificates git \
    && rm -rf /var/lib/apt/lists/*

RUN git clone https://github.com/TotallyNotRobots/CloudBot.git /usr/src/cloudbot \
    && cd /usr/src/cloudbot \
    && git checkout --detach "${CLOUDBOT_COMMIT}" \
    && test "$(git rev-parse HEAD)" = "${CLOUDBOT_COMMIT}"

RUN python -m venv "$VIRTUAL_ENV" \
    && "$VIRTUAL_ENV/bin/python" -m pip install --upgrade pip wheel \
    && "$VIRTUAL_ENV/bin/python" -m pip install -r /usr/src/cloudbot/requirements.txt

FROM python:${PYTHON_VERSION}-slim-bookworm

ARG VERSION=0.1.0
ARG CLOUDBOT_VERSION=1.4.0
ARG CLOUDBOT_COMMIT=d891d49254d5c95ddd997c0d44e03a502966ba34

LABEL org.opencontainers.image.title="CloudBot" \
      org.opencontainers.image.description="Production-oriented OCI image for CloudBot" \
      org.opencontainers.image.url="https://github.com/Ploos-AS/cloudbot" \
      org.opencontainers.image.source="https://github.com/Ploos-AS/cloudbot" \
      org.opencontainers.image.documentation="https://github.com/Ploos-AS/cloudbot#readme" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.licenses="GPL-3.0-or-later" \
      io.ploos.cloudbot.upstream.version="${CLOUDBOT_VERSION}" \
      io.ploos.cloudbot.upstream.commit="${CLOUDBOT_COMMIT}"

RUN apt-get update \
    && apt-get install --yes --no-install-recommends ca-certificates tini \
    && rm -rf /var/lib/apt/lists/* \
    && groupadd --gid 1000 cloudbot \
    && useradd --uid 1000 --gid 1000 --home-dir /data --no-create-home --shell /usr/sbin/nologin cloudbot \
    && mkdir -p /data /usr/src \
    && chown 1000:1000 /data

COPY --from=builder /opt/cloudbot/venv /opt/cloudbot/venv
COPY --from=builder /usr/src/cloudbot /usr/src/cloudbot
COPY rootfs/usr/local/bin/cloudbot-entrypoint /usr/local/bin/cloudbot-entrypoint
COPY rootfs/usr/local/bin/cloudbot-healthcheck /usr/local/bin/cloudbot-healthcheck

RUN chmod 0755 /usr/local/bin/cloudbot-entrypoint /usr/local/bin/cloudbot-healthcheck

ENV PATH="/opt/cloudbot/venv/bin:${PATH}" \
    HOME=/data \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    CLOUDBOT_CONFIG=/data/config.json

WORKDIR /data
VOLUME ["/data"]
USER 1000:1000

HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 CMD ["/usr/local/bin/cloudbot-healthcheck"]

ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/bin/cloudbot-entrypoint"]
CMD ["run"]
