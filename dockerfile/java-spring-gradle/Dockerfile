FROM public.ecr.aws/docker/library/alpine:3.20 as build

RUN apk add --no-cache openjdk21-jdk

WORKDIR /app

COPY *gradle* .
COPY gradle gradle

RUN sh ./gradlew dependencies

COPY src src

RUN sh ./gradlew bootjar

FROM public.ecr.aws/docker/library/alpine:3.20 as runtime

ARG user=1000
ARG group=1000

RUN apk add --no-cache openjdk21-jre curl ngrep

WORKDIR /app
USER $user:$group

COPY --from=build /app/build/libs/*.jar /app/

ENTRYPOINT ["/bin/sh", "-c", "java -jar *.jar"]
