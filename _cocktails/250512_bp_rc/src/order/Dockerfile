FROM public.ecr.aws/docker/library/alpine:3.20

RUN apk add --no-cache curl ngrep gcompat

ARG user=1000
ARG group=1000

USER $user:$group
WORKDIR /app

COPY --chown=$user:$group order .

RUN chmod +x order

ENTRYPOINT ["/app/order"]
