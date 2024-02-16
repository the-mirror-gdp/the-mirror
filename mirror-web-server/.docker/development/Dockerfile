# Build with ( !! start in mirror-docker-container directory !!):
#  docker build -f ./src-code/rest-server/.docker/development/dockerfile -t mirror-rest-server .
#
# Run with:
#  docker run --name mirror-rest-server --rm --detach -v $(pwd)/src-code/rest-server:/mirror/rest-server -p 3000:3000 mirror-rest-server
#

FROM node:current-alpine3.14
LABEL product="mirror-web-server API"
LABEL mode="Development"

# This lets us copy over config files needed to serve the application
COPY .docker /docker

RUN apk update \
    && apk add --no-cache \
        python2 \
        g++ \
        make \
        nano \
        npm \
        yarn \
        jq \
    && mkdir -p /mirror/rest-server \
    && sed -i -e 's/\r$//' /docker/start.sh

WORKDIR /mirror/rest-server

EXPOSE 9000 9001 9230

RUN npm install @nestjs/cli -g

CMD ["sh", "/docker/start.sh"]
