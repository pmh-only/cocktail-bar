FROM public.ecr.aws/docker/library/alpine:3.20 AS build

RUN apk add --no-cache go

WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY . /app/
ENV CGO_ENABLED=0
RUN go build -o /app/main

FROM public.ecr.aws/docker/library/alpine:3.20 AS runtime

RUN apk add --no-cache curl

ARG user=1000
ARG group=1000

USER $user:$group
WORKDIR /app

COPY --from=build /app/main .

ENTRYPOINT ["/app/main"]
