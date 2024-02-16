# I'm aiming to not have to build this locally because Docker is slow. Use 'yarn dev' instead.

# Try busybox distro in the future for faster performance??
FROM node:18

# Used to override the db name to not use "themirror".
ARG OVERRIDE_DB_NAME=''
ENV OVERRIDE_DB_NAME=$OVERRIDE_DB_NAME

WORKDIR /app

COPY package.json .
COPY yarn.lock .

RUN yarn --frozen-lockfile

COPY . .

COPY auto-migrate.sh /auto-migrate.sh
RUN chmod +x /auto-migrate.sh

RUN yarn gcp-build

EXPOSE 3000 9000 9001 8080

ENTRYPOINT [ "/auto-migrate.sh" ]
CMD [ "start:prod" ]