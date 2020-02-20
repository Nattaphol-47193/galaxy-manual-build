# Galaxy

Galaxy is web application, provides new customizable dashboard and support mysql and elasticsearch datasource.

## Installation

## Building

```
make clean
make
```

## Running

### Runing backend

```
api-server
```

### Running frontend

```
yarn start
```

Open galaxy in your browser (default: e.g. http://localhost:80) and login with admin user (default: user/pass = admin/admin).

## Package Galaxy in docker

```
make build-docker-dev
or
make build-docker-full
```

The resulting image will be tagged as galaxy/galaxy:dev

### Testing
