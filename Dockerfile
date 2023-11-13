FROM golang:alpine AS Builder

WORKDIR /src

ENV CGO_CFLAGS="-g -O2 -Wno-return-local-addr"

RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.ustc.edu.cn/g' /etc/apk/repositories && \
    echo "Asia/Shanghai" > /etc/timezone && \
    apk add build-base git ca-certificates && \
    git clone https://github.com/harness/gitness.git -b drone -o drone

WORKDIR /src/drone

RUN go env -w GOPROXY="https://goproxy.cn,direct" && \
    go mod download && \
    go build -ldflags "-extldflags \"-static\"" -tags="nolimit" cmd/drone-server


FROM alpine

VOLUME /data

RUN echo 'hosts: files dns' > /etc/nsswitch.conf

ENV GODEBUG netdns=go \
    XDG_CACHE_HOME /data \
    DRONE_DATABASE_DRIVER sqlite3 \
    DRONE_DATABASE_DATASOURCE /data/database.sqlite \
    DRONE_RUNNER_OS=linux \
    DRONE_RUNNER_ARCH=amd64 \
    DRONE_SERVER_PORT=:80 \
    DRONE_SERVER_HOST=localhost \
    DRONE_DATADOG_ENABLED=true \
    DRONE_DATADOG_ENDPOINT=https://stats.drone.ci/api/v1/series

COPY --from=Builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=Builder /src/drone/drone-server /bin/drone-server

EXPOSE 80 443

ENTRYPOINT ["/bin/drone-server"]
