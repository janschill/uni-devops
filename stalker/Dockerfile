FROM ruby:2.6.5-alpine3.11

RUN apk add build-base && \
    apk add --no-cache git && \
    gem install bundler

WORKDIR /var/www

COPY ./ /var/www/stalker/
RUN cd stalker && \
    bundle

RUN echo -e "#!/bin/sh\n\
    cd stalker \n\
    bundle exec rake stalker:start[1] \n\
    " >> start.sh && chmod +x start.sh

ENTRYPOINT ["./start.sh"]
