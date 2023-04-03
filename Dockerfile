# syntax=docker/dockerfile:1.4

# 1. For build React app
FROM node:lts AS development

# Set working directory
WORKDIR /app

# 
COPY package.json /app/package.json
COPY package-lock.json /app/package-lock.json

# Same as npm install
RUN npm ci

COPY . /app

ENV CI=true
ENV PORT=3000

CMD [ "npm", "start" ]

FROM development AS build

RUN npm run build

# 2. For Nginx setup
FROM nginx:alpine

# Copy config nginx
RUN echo "server {" > /etc/nginx/conf.d/default.conf
RUN echo "" >> /etc/nginx/conf.d/default.conf
RUN echo "  listen 80;" >> /etc/nginx/conf.d/default.conf
RUN echo "" >> /etc/nginx/conf.d/default.conf
RUN echo "  location / {" >> /etc/nginx/conf.d/default.conf
RUN echo "    root   /usr/share/nginx/html;" >> /etc/nginx/conf.d/default.conf
RUN echo "    index  index.html index.htm;" >> /etc/nginx/conf.d/default.conf
RUN echo "    try_files $uri /index.html =404;" >> /etc/nginx/conf.d/default.conf
RUN echo "  }" >> /etc/nginx/conf.d/default.conf
RUN echo "" >> /etc/nginx/conf.d/default.conf
RUN echo "  error_page   500 502 503 504  /50x.html;" >> /etc/nginx/conf.d/default.conf
RUN echo "" >> /etc/nginx/conf.d/default.conf
RUN echo "  location = /50x.html {" >> /etc/nginx/conf.d/default.conf
RUN echo "    root   /usr/share/nginx/html;" >> /etc/nginx/conf.d/default.conf
RUN echo "  }" >> /etc/nginx/conf.d/default.conf
RUN echo "}" >> /etc/nginx/conf.d/default.conf

WORKDIR /usr/share/nginx/html

# Remove default nginx static assets
RUN rm -rf ./*

# Copy static assets from builder stage
COPY --from=build /app/build .

# Containers run nginx with global directives and daemon off
ENTRYPOINT ["nginx", "-g", "daemon off;"]