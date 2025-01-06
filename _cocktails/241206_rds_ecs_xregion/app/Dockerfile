FROM scratch

USER 1000:1000

WORKDIR /app

COPY --chown=1000:1000 ./app ./app

ENTRYPOINT [ "./app" ]
