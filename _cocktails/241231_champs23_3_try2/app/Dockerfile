FROM public.ecr.aws/docker/library/alpine

ARG user=1000
ARG group=1000

USER $user:$group
WORKDIR /app

COPY --chown=$user:$group location-arm64 .

ENTRYPOINT ["/app/location-arm64"]
