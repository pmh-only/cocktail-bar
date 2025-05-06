FROM public.ecr.aws/docker/library/alpine:3.20

ARG user=1000
ARG group=1000

RUN apk add --no-cache openjdk21-jre curl ngrep

USER $user:$group
WORKDIR /app

COPY app.jar .

ENTRYPOINT ["java", "-jar", "app.jar"]
