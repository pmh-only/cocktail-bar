FROM public.ecr.aws/docker/library/alpine:latest

ARG APP=stress

WORKDIR /app

USER 1000:1000

COPY --chown=1000:1000 ./${APP} /app/${APP}

RUN chmod +x /app/${APP}

ENTRYPOINT ["/app/${APP}"]
