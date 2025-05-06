FROM public.ecr.aws/docker/library/alpine:3.20 as build

RUN apk add --no-cache python3 py3-pip

WORKDIR /app

COPY requirements.txt .

RUN pip install -t .lib -r requirements.txt

# ---

FROM public.ecr.aws/docker/library/alpine:3.20 as runtime

ARG user=1000
ARG group=1000

RUN apk add --no-cache python3 curl ngrep

USER $user:$group
WORKDIR /app

COPY --from=build /app/.lib .lib
COPY src src

ENV PYTHONPATH=/app/.lib
ENTRYPOINT ["/usr/bin/python3", "src/app.py"]
