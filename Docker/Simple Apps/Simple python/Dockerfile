FROM python:3.6-alpine3.13

RUN ln -snf /usr/share/zoneinfo/Europe/Moscow /etc/localtime && \
	echo Europe/Moscow > /etc/timezone

RUN set -ex && \
	apt-get update -y && \
	apt-get install -y curl && \
	rm -rf /var/lib/apt/lists/*
	
RUN pip install django

ADD . /app
ENTRYPOINT python /app/manage.py runserver 0.0.0.0:8000 --noreload
