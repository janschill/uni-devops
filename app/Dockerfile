FROM ruby:2.6.5-alpine3.11

EXPOSE 80

RUN apk add build-base && \
    apk add sqlite-dev && \
    apk add sqlite && \
    gem install bundler

# Make sure Gems are cached
WORKDIR /var/www/
COPY Gemfile* /tmp/appgems/

WORKDIR /tmp/appgems
RUN bundle install

WORKDIR /var/www

COPY ./* /var/www/app/
RUN cd app && \
    bundle

WORKDIR /var/www

RUN echo -e "#!/bin/sh\n\
    cd app \n\
    bundle exec rake app:start \n\
    tail -f /dev/null \n\
    " >> start.sh && chmod +x start.sh

ENTRYPOINT ["./start.sh"]
