# FROM python:3.9-alpine as builder
FROM python:3.10-slim as builder
ARG INDEX_URL

ENV INDEX_URL=$INDEX_URL
#RUN apk add --update python3 py-pip python3-dev cmake gcc g++ openssl1.1-compat-dev build-base
RUN apt-get update && apt-get install -y build-essential cmake libssl-dev libffi-dev python3-dev tzdata

COPY requirements.txt .
RUN pip install --user --no-cache-dir -r requirements.txt

FROM python:3.10-slim
COPY --from=builder /root/.local /root/.local
ENV TZ=Europe/Stockholm
ENV PATH=/root/.local/bin:$PATH

WORKDIR /code
COPY ./app /code/app

EXPOSE 80
CMD ["python3", "run.py"]