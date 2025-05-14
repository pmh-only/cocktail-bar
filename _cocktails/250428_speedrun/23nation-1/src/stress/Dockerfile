FROM public.ecr.aws/docker/library/alpine:3.20

RUN apk add --no-cache curl ngrep

ARG user=1000
ARG group=1000

USER $user:$group
WORKDIR /app

COPY --chown=$user:$group stress-amd64 .

RUN chmod +x stress-amd64

RUN mkdir /app/log
RUN touch /app/log/app.log

RUN ln -sf /dev/stdout /app/log/app.log

ENTRYPOINT ["/app/stress-amd64"]
