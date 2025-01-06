FROM alpine

ARG user=1000
ARG group=1000

USER $user:$group
WORKDIR /app

COPY --chown=$user:$group unicorn-arm64 .

ENTRYPOINT ["/app/unicorn-arm64"]
