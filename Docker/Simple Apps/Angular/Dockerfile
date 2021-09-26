FROM node:15.4 as build 

WORKDIR /app
COPY package*.json .
RUN npm install 
COPY . .
RUN npm run prod

FROM nginx:alpine 

COPY ./nginx/nginx.conf /etc/nginx/nginx.conf
COPY --from=build /app/dist/angular-chat /usr/share/nginx/html

#dist/project-name

EXPOSE 80 443
#CMD [ "nginx", "-g", "daemon off;" ]

#docker build -t app .
#docker run -p 80:80 app