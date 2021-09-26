FROM node:15.4 as build 

WORKDIR /app
COPY package*.json .
RUN npm install 
COPY . .
RUN npm run build 

FROM node:15.4

WORKDIR /app

COPY package.json .
#install only dependencies from package.json file 
RUN npm install --only=production 
COPY --from=build /app/dist ./dist
CMD npm run start:prod 

#docker build -t app .
#docker run -p :80 app