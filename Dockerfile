FROM node:latest

WORKDIR /usr/src/app

COPY package*.json ./

RUN npm install

COPY index.js ./
COPY views ./views/

EXPOSE 8100


CMD ["node" , "index.js"]