FROM public.ecr.aws/amazonlinux/amazonlinux:2023

ARG user=1000
ARG group=1000

RUN yum install -y aws-cli jq

USER $user:$group
WORKDIR /app

COPY --chown=$user:$group app .
COPY --chown=$user:$group run.sh .
COPY --chown=$user:$group healthcheck.sh .

RUN chmod +x app
RUN chmod +x run.sh
RUN chmod +x healthcheck.sh

ENTRYPOINT ["/app/run.sh"]
