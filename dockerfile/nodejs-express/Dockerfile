FROM public.ecr.aws/docker/library/alpine:3.20 as build

RUN apk add --no-cache nodejs
RUN apk add --no-cache npm

WORKDIR /app

COPY package.json \
     package-lock.json \
     ./

RUN npm i

FROM public.ecr.aws/docker/library/alpine:3.20 as runtime

RUN apk add --no-cache nodejs curl ngrep

ARG user=1000
ARG group=1000

USER $user:$group
WORKDIR /app

COPY --from=build /app/node_modules node_modules
COPY src src

ENTRYPOINT ["/usr/bin/node", "src/main.js"]
