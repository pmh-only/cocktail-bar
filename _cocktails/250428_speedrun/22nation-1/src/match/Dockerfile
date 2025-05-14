FROM public.ecr.aws/docker/library/alpine:3.20

RUN apk add --no-cache curl ngrep gcompat
RUN addgroup -S match && adduser -S match -G match

ARG user=match
ARG group=match

USER $user:$group
WORKDIR /app

COPY --chown=$user:$group match .

RUN chmod +x match

ENTRYPOINT ["/app/match"]
