FROM public.ecr.aws/docker/library/alpine:3.20

RUN apk add --no-cache curl ngrep

ARG user=1000
ARG group=1000

USER $user:$group
WORKDIR /app

COPY --chown=$user:$group main .

RUN chmod +x main

ENTRYPOINT ["/app/main"]
