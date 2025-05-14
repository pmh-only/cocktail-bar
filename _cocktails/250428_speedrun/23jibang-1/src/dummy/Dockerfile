FROM public.ecr.aws/docker/library/alpine:3.20 AS build

RUN apk add --no-cache go

WORKDIR /app

RUN go mod init main

COPY . /app/
ENV CGO_ENABLED=0
RUN go build -o /app/main

FROM public.ecr.aws/docker/library/alpine:3.20 AS runtime

RUN apk add --no-cache curl
RUN addgroup -S jncuser && adduser -S jncuser -G jncuser

ARG user=jncuser
ARG group=jncuser

USER $user:$group
WORKDIR /app

COPY --from=build /app/main .

ENTRYPOINT ["/app/main"]
