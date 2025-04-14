FROM public.ecr.aws/nginx/nginx:stable-alpine3.20-slim

RUN apk add --no-cache curl

RUN echo "ok" > /usr/share/nginx/html/health

COPY default.conf /etc/nginx/conf.d/default.conf
