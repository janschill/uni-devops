FROM ruby:2.6.5-alpine3.11

EXPOSE 80
EXPOSE 1337

RUN apk add build-base && \
    apk add sqlite-dev && \
    apk add sqlite && \
    gem install bundler

# Make sure Gems are cached
WORKDIR /var/www/
COPY app/Gemfile* /tmp/appgems/
COPY api/Gemfile* /tmp/apigems/

WORKDIR /tmp/appgems
RUN bundle install

WORKDIR /tmp/apigems
RUN bundle install

WORKDIR /var/www

COPY ./api /var/www/api
COPY ./app /var/www/app
RUN cd app && \
    bundle

WORKDIR /var/www/app

RUN echo -e " \n\
    DATABASE_NAME=minitwit \n\
    ENVIRONMENT= \n\
    SESSION_KEY=AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA \n\
    SESSION_RAND=AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA \n\
    " >> .env

RUN ./bin/control.rb init

WORKDIR /var/www

RUN echo -e "#!/bin/sh\n\
    cd api \n\
    rackup -p 1337 -o 0.0.0.0 & \n\
    cd .. \n\
    cd app \n\
    rackup -p 80 -o 0.0.0.0\n\
    " >> start.sh && chmod +x start.sh

ENTRYPOINT ["./start.sh"]
