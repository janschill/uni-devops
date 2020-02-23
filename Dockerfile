FROM ruby:2.6.5-alpine3.11

COPY ./ /var/www/

WORKDIR /var/www/

RUN apk add build-base && \
    apk add sqlite-dev && \
    apk add sqlite && \
    gem install bundler

RUN cd app && \
    bundle