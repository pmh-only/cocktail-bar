FROM public.ecr.aws/docker/library/alpine

RUN apk add --no-cache gcompat

ARG user=1000
ARG group=1000

USER $user:$group
WORKDIR /app

COPY main .

ENTRYPOINT ["/app/main"]
