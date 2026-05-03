FROM node:20-alpine

WORKDIR /app

# install OSRM dependencies
RUN apk add --no-cache \
    curl \
    wget \
    ca-certificates

COPY package.json .
RUN npm install --production

COPY src/ src/

# create data directory for OSM files
RUN mkdir -p /data/osm

EXPOSE 4001
EXPOSE 8080

CMD ["node", "src/index.js"]
