#############
### build ###
#############

# base image
FROM node:14.20 AS build

RUN echo "deb http://archive.debian.org/debian stretch main" > /etc/apt/sources.list
RUN echo "deb http://archive.debian.org/debian-security stretch/updates main" >> /etc/apt/sources.list

# install chrome for protractor tests
RUN apt-get update && apt-get install

# set working directory
WORKDIR /app

# add `/app/node_modules/.bin` to $PATH
ENV PATH=/app/node_modules/.bin:$PATH

# install and cache app dependencies
COPY ./clients/html/package.json /app/package.json
COPY ./clients/html/package-lock.json /app/package-lock.json
RUN npm ci

# add app
COPY ./clients/html/ /app

# run tests
#RUN ng test --watch=false
#RUN ng e2e --port 4202

ARG API_URL
RUN sed -i -r "s/API_URL/$API_URL/g" /app/src/environments/environment.prod.ts

# generate build
RUN npm run build:prod

############
### prod ###
############

# base image
FROM nginx:1.24.0-alpine

# copy artifact build from the 'build environment'
COPY --from=build /app/dist /usr/share/nginx/html

# copy nginx configuration
ARG API_URL
COPY ./.docker/production/web/nginx.conf /etc/nginx/conf.d/$API_URL.conf
RUN sed -i -r "s/API_URL/$API_URL/g" /etc/nginx/conf.d/$API_URL.conf 

# expose port 80
#EXPOSE 80

# run nginx
#CMD ["nginx", "-g", "daemon off;"]
