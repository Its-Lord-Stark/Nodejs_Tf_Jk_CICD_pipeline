# FROM node:alpine

# WORKDIR /usr/src/app

# COPY package*.json ./

# RUN npm install

# COPY index.js ./
# COPY views ./views/

# EXPOSE 8100


# CMD ["node" , "index.js"]


FROM alpine:latest
CMD ["echo", "Hello, World!"]
