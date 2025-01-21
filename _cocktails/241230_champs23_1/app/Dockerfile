FROM public.ecr.aws/docker/library/alpine as build

RUN apk add --no-cache python3
RUN apk add --no-cache py3-pip

WORKDIR /app

RUN pip install -t .lib flask

# ---

FROM public.ecr.aws/docker/library/alpine as runtime

ARG user=1000
ARG group=1000

RUN apk add --no-cache python3 curl

USER $user:$group
WORKDIR /app

COPY --from=build /app/.lib .lib
COPY green.py /app/green.py

ENV PYTHONPATH=/app/.lib
ENTRYPOINT ["/usr/bin/python3", "/app/green.py"]
