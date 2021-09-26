FROM node:15.4 as build 

WORKDIR /app
COPY package*.json .
RUN npm install 
COPY . .
RUN npm build 

FROM nginx:latest

COPY ./nginx/nginx.conf /etc/nginx/nginx.conf
COPY --from=build /app/public /usr/share/nginx/html


#docker build -t app .
#docker run -p 80:80 app