FROM python:3.7-alpine

RUN pip install flask

COPY app.py .

ENTRYPOINT [ "python", "app.py" ]
