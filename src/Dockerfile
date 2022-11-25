FROM python:3.9.14-alpine

COPY ./requirements.txt /app/requirements.txt

WORKDIR /app

RUN pip install -r requirements.txt

COPY . /app
EXPOSE 5000

CMD gunicorn --bind 0.0.0.0:5000 main:app
