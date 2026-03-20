ARG RUBY_VERSION
FROM ruby:$RUBY_VERSION

ARG BUNDLER_VERSION
ARG NODE_MAJOR
ARG YARN_VERSION

# Add NodeJS to sources list
RUN curl -sL https://deb.nodesource.com/setup_$NODE_MAJOR.x | bash -

# Add Yarn to the sources list (apt-key removed in Debian 13)
RUN apt-get update -qq \
  && DEBIAN_FRONTEND=noninteractive apt-get install -yq --no-install-recommends gnupg \
  && mkdir -p /etc/apt/keyrings \
  && curl -fsSL https://dl.yarnpkg.com/debian/pubkey.gpg \
    | gpg --dearmor -o /etc/apt/keyrings/yarn-archive-keyring.gpg \
  && echo 'deb [signed-by=/etc/apt/keyrings/yarn-archive-keyring.gpg] http://dl.yarnpkg.com/debian/ stable main' \
    > /etc/apt/sources.list.d/yarn.list \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

# Install dependencies
COPY .dockerdev/Aptfile /tmp/Aptfile
RUN apt-get update -qq && DEBIAN_FRONTEND=noninteractive apt-get -yq dist-upgrade && \
  DEBIAN_FRONTEND=noninteractive apt-get install -yq --no-install-recommends \
    build-essential \
    nodejs \
    yarn=$YARN_VERSION-1 \
    $(cat /tmp/Aptfile | xargs) && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    truncate -s 0 /var/log/*log

# Upgrade RubyGems and install required Bundler version
RUN gem update --system && \
    gem install bundler:$BUNDLER_VERSION

# Configure bundler and PATH (set after Bundler install so the gem isn't
# installed into the /bundle volume during image build)
ENV LANG=C.UTF-8 \
  GEM_HOME=/bundle \
  GEM_PATH=/bundle:/usr/local/bundle \
  BUNDLE_JOBS=4 \
  BUNDLE_RETRY=3
ENV BUNDLE_PATH $GEM_HOME
ENV BUNDLE_APP_CONFIG=$BUNDLE_PATH \
  BUNDLE_BIN=$BUNDLE_PATH/bin
ENV PATH /app/bin:$BUNDLE_BIN:$PATH

# Create a directory for the app code
RUN mkdir -p /app

WORKDIR /app
COPY . .
