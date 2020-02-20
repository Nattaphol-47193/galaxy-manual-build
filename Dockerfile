# Golang build container
FROM golang:1.11.5

WORKDIR $GOPATH/src/github.com/netkasystem/galaxy

COPY go.mod go.sum ./
COPY vendor vendor

COPY pkg pkg
COPY build.go build.go
COPY package.json package.json
COPY galaxy-server galaxy-server 
COPY galaxy-cli galaxy-cli
COPY galaxy-reporter galaxy-reporter
COPY netka-plugin-model netka-plugin-model 

RUN go run build.go build

# Node build container
FROM node:10.14.2

WORKDIR /usr/src/app/

COPY package.json yarn.lock ./
COPY packages packages

RUN yarn install --pure-lockfile --no-progress

COPY Gruntfile.js tsconfig.json tslint.json ./
COPY public public
COPY scripts scripts
COPY emails emails

ENV NODE_ENV production
RUN ./node_modules/.bin/grunt build

# Final container
FROM debian:stretch-slim

ARG GALAXY_UID="472"
ARG GALAXY_GID="472"

ENV PATH=/usr/share/galaxy/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
    GALAXY_PATHS_CONFIG="/etc/galaxy/galaxy.ini" \
    GALAXY_PATHS_DATA="/var/lib/galaxy" \
    GALAXY_PATHS_HOME="/usr/share/galaxy" \
    GALAXY_PATHS_LOGS="/var/log/galaxy" \
    GALAXY_PATHS_PLUGINS="/var/lib/galaxy/plugins" \
    GALAXY_PATHS_PROVISIONING="/etc/galaxy/provisioning"

WORKDIR $GALAXY_PATHS_HOME

RUN apt-get update && apt-get upgrade -y && \
    apt-get install -qq -y libfontconfig ca-certificates && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/*

COPY conf ./conf

RUN mkdir -p "$GALAXY_PATHS_HOME/.aws" && \
    groupadd -r -g $GALAXY_GID galaxy && \
    useradd -r -u $GALAXY_UID -g galaxy galaxy && \
    mkdir -p "$GALAXY_PATHS_PROVISIONING/datasources" \
    "$GALAXY_PATHS_PROVISIONING/dashboards" \
    "$GALAXY_PATHS_PROVISIONING/notifiers" \
    "$GALAXY_PATHS_LOGS" \
    "$GALAXY_PATHS_PLUGINS" \
    "$GALAXY_PATHS_DATA" && \
    cp "$GALAXY_PATHS_HOME/conf/sample.ini" "$GALAXY_PATHS_CONFIG" && \
    cp "$GALAXY_PATHS_HOME/conf/ldap.toml" /etc/galaxy/ldap.toml && \
    chown -R galaxy:galaxy "$GALAXY_PATHS_DATA" "$GALAXY_PATHS_HOME/.aws" "$GALAXY_PATHS_LOGS" "$GALAXY_PATHS_PLUGINS" && \
    chmod 777 "$GALAXY_PATHS_DATA" "$GALAXY_PATHS_HOME/.aws" "$GALAXY_PATHS_LOGS" "$GALAXY_PATHS_PLUGINS"

COPY --from=0 /go/src/github.com/netkasystem/galaxy/bin/linux-amd64/galaxy-server /go/src/github.com/netkasystem/galaxy/bin/linux-amd64/galaxy-cli ./bin/
COPY --from=0 /go/src/github.com/netkasystem/galaxy/bin/linux-amd64/galaxy-reporter ./bin/
COPY --from=1 /usr/src/app/public ./public
COPY --from=1 /usr/src/app/tools ./tools
COPY tools/phantomjs/render.js ./tools/phantomjs/render.js

EXPOSE 80

COPY ./packaging/docker/run.sh /run.sh

USER galaxy
ENTRYPOINT [ "/run.sh" ]