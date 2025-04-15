docker build --platform linux/amd64 --build-arg API_URL="$1"'.mhc.hbxshop.org' -f .docker/production/web/Dockerfile -t ghcr.io/health-connector/nginx:$2 .
docker push ghcr.io/health-connector/nginx:$2
