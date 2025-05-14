FROM public.ecr.aws/docker/library/alpine:3.20

RUN apk add --no-cache curl ngrep gcompat
RUN addgroup -S stress && adduser -S stress -G stress

ARG user=stress
ARG group=stress

USER $user:$group
WORKDIR /app

COPY --chown=$user:$group stress .

RUN chmod +x stress

ENTRYPOINT ["/app/stress"]
