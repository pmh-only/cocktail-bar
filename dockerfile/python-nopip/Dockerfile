FROM public.ecr.aws/docker/library/alpine:3.20

ARG user=1000
ARG group=1000

RUN apk add --no-cache python3 curl

USER $user:$group

WORKDIR /app

COPY src/. .

ENTRYPOINT ["/usr/bin/python"]
CMD ["app.py"]
