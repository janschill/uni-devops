FROM ruby:2.6.5-alpine3.11

COPY ./api /var/www/api
COPY ./app /var/www/app

WORKDIR /var/www/

RUN apk add build-base && \
    apk add sqlite-dev && \
    apk add sqlite && \
    gem install bundler

RUN cd app && \
    bundle

EXPOSE 80

WORKDIR ./app

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