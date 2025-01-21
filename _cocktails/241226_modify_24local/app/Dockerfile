FROM public.ecr.aws/docker/library/alpine

RUN apk add --no-cache curl

ARG user=1000
ARG group=1000

USER $user:$group
WORKDIR /app

COPY --chown=1000:1000 token .

ENTRYPOINT ["/app/token"]
