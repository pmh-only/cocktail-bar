FROM public.ecr.aws/docker/library/alpine

RUN apk add --no-cache curl gcompat

ARG user=1000
ARG group=1000

USER $user:$group
WORKDIR /app

COPY product .

ENTRYPOINT ["/app/product"]
