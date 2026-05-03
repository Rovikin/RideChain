# RideChain Node

Super node untuk infrastruktur routing dan P2P discovery.

## Persiapan data OSM

```bash
mkdir -p data/osm
cd data/osm

# download data OSM Indonesia
wget https://download.geofabrik.de/asia/indonesia-latest.osm.pbf

# proses untuk OSRM
docker run -t -v $(pwd):/data \
  ghcr.io/project-osrm/osrm-backend \
  osrm-extract -p /opt/car.lua /data/indonesia-latest.osm.pbf

docker run -t -v $(pwd):/data \
  ghcr.io/project-osrm/osrm-backend \
  osrm-partition /data/indonesia-latest.osrm

docker run -t -v $(pwd):/data \
  ghcr.io/project-osrm/osrm-backend \
  osrm-customize /data/indonesia-latest.osrm
