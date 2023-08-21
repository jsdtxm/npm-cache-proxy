# === BUILD STAGE === #
FROM golang:1.12-alpine as build

ARG ACCESS_TOKEN

RUN apk add --no-cache git

WORKDIR /srv/app
ENV CGO_ENABLED=0 GOOS=linux GOARCH=amd64

COPY go.mod go.sum ./

ENV GOPROXY https://mirrors.aliyun.com/goproxy/

RUN go mod download

COPY . .
RUN go test -v ./...
RUN go build -ldflags="-w -s" -o ncp

# === RUN STAGE === #
FROM redis:6.2-alpine as run

RUN apk update \
        && apk upgrade \
        && apk add --no-cache ca-certificates \
        && update-ca-certificates \
        && rm -rf /var/cache/apk/*
        
WORKDIR /srv/app
COPY --from=build /srv/app/ncp /srv/app/ncp
COPY entrypoint.sh /srv/app/entrypoint.sh

VOLUME /data

ENV REDIS_PASSWORD password
ENV REDIS_ADDRESS 127.0.0.1:6379
ENV UPSTREAM_ADDRESS https://registry.npmmirror.com

ENV LISTEN_ADDRESS 0.0.0.0:8080
ENV GIN_MODE release

CMD ["sh", "/srv/app/entrypoint.sh"]
