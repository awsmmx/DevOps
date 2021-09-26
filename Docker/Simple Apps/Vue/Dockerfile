FROM node:15.4 as build 

WORKDIR /app
COPY package*.json .
RUN npm install 
COPY . . 
RUN npm run build 


FROM nginx:latest

COPY ./nginx/nginx.conf /etc/nginx/nginx.conf
COPY --from=build /app/dist /usr/share/nginx/html


#docker build -t app .
#docker run -p :80 app