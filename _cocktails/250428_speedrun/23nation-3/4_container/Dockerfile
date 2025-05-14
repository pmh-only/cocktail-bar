FROM public.ecr.aws/docker/library/alpine:3.20 AS build

RUN apk add --no-cache go

WORKDIR /app

COPY src/* /app/

ENV CGO_ENABLED=0

RUN go mod tidy
RUN go mod download
RUN go build -o /app/main

FROM public.ecr.aws/docker/library/alpine:3.20 AS runtime

RUN apk add --no-cache curl

ARG user=1000
ARG group=1000

USER $user:$group
WORKDIR /app

COPY --from=build /app/main .

ENTRYPOINT ["/app/main"]
