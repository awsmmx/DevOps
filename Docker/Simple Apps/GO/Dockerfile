FROM golang:1.16-alpine

WORKDIR /app

COPY go.mod .
COPY go.sum .
RUN go mod download 
COPY . . 
RUN go build -o ./out/dist .
CMD ./out/dist 


#docker build -t app .
#docker run -p 80:80 app