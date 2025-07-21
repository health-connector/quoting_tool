docker build --build-arg RUBY_VERSION='3.1.6' --build-arg BUNDLER_VERSION='2.0.2' --build-arg NODE_MAJOR='11' --build-arg YARN_VERSION='1.17.3' -f .docker/development/app/Dockerfile.faketime -t ideacrew/quoting_tool_app:$2 .
docker build --build-arg API_URL="$1"'.mhc.hbxshop.org' -f .docker/production/web/Dockerfile -t ideacrew/quoting_tool_web:$2 .
docker push ideacrew/quoting_tool_web:$2
docker push ideacrew/quoting_tool_app:$2
