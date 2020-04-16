FROM ruby:2.6.5-alpine3.11

EXPOSE 1337

RUN apk add build-base && \
    apk add mariadb-dev && \
    gem install bundler

# Make sure Gems are cached
WORKDIR /var/www/
COPY Gemfile* /tmp/apigems/

WORKDIR /tmp/apigems
RUN bundle install

WORKDIR /var/www

COPY ./ /var/www/api/
RUN cd api && \
    bundle

WORKDIR /var/www

RUN echo -e "#!/bin/sh\n\
    cd api \n\
    bundle exec rake api:start \n\
    tail -f /dev/null \n\
    " >> start.sh && chmod +x start.sh

ENTRYPOINT ["./start.sh"]
