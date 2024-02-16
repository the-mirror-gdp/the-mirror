FROM node:18
WORKDIR /app

RUN npm i -g @nestjs/cli
# yarn configuration files
COPY package.json yarn.lock ./
RUN yarn 
COPY . .
RUN chmod +x ./auto-migrate.sh
EXPOSE 3000 9000 9001 8080
ENTRYPOINT [ "./auto-migrate.sh" ]
CMD [ "dev" ]