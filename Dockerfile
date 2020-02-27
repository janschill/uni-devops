FROM ruby:2.6.5-alpine3.11

COPY ./api /var/www/api
COPY ./app /var/www/app

WORKDIR /var/www/

RUN apk add build-base && \
    apk add sqlite-dev && \
    apk add sqlite && \
    gem install bundler

RUN cd app && \
    bundle && \
    cd ../api && \
    bundle

EXPOSE 80
EXPOSE 1337

WORKDIR /var/www/

RUN echo -e "#!/bin/sh\n\
    cd api \n\
    bundle exec rake api:start \n\
    cd .. \n\
    cd app \n\
    bundle exec rake app:start \n\
    tail -f /dev/null \n\
    " >> start.sh && chmod +x start.sh

ENTRYPOINT ["./start.sh"]
