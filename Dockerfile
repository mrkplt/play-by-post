# syntax=docker/dockerfile:1
# check=error=true

ARG RUBY_VERSION=3.3.6
FROM docker.io/library/ruby:$RUBY_VERSION-slim AS base

WORKDIR /rails

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
      curl \
      ghostscript \
      imagemagick \
      libvips \
      poppler-utils \
      sqlite3 && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

ENV RAILS_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development:test"

# Build stage — compilers, headers, node/yarn for assets
FROM base AS build

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
      build-essential \
      git \
      node-gyp \
      pkg-config \
      python-is-python3 && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

ARG NODE_VERSION=22.22.2
ARG YARN_VERSION=1.22.22
ENV PATH=/usr/local/node/bin:$PATH

RUN curl -sL https://github.com/nodenv/node-build/archive/master.tar.gz | tar xz -C /tmp/ && \
    /tmp/node-build-master/bin/node-build "${NODE_VERSION}" /usr/local/node && \
    npm install -g yarn@$YARN_VERSION && \
    rm -rf /tmp/node-build-master

COPY Gemfile Gemfile.lock ./
RUN bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git && \
    bundle exec bootsnap precompile --gemfile

COPY package.json yarn.lock ./
RUN yarn install --frozen-lockfile

COPY . .

RUN bundle exec bootsnap precompile app/ lib/

RUN SECRET_KEY_BASE_DUMMY=1 ./bin/rails assets:precompile

# Final images — runtime only, no build tools or node. Split in two so the AI
# Control Plane's worker-only secrets (the AR-encryption key file for the
# private-key database, config/ai_private_keys.key) are structurally confined
# to the worker image. web-final copies /rails from this intermediate
# `app-export` stage rather than from `build` directly: app-export deletes the
# key file (and its private-key database) right after copying, so that layer —
# and everything derived from it — never contains the secret. worker-final
# copies /rails straight from `build`, unmodified, so it keeps the key file.
# Do not change web-final to COPY --from=build under any circumstance — that
# would put the secret back in the web image. See docs/CONFIGURATION.md.
FROM base AS app-export
COPY --from=build /rails /rails
# `rm -f` (not `rm`) so this does not fail while these files don't exist yet —
# they are added by a separate change — or in any future state where they are
# legitimately absent.
RUN rm -f /rails/config/ai_private_keys.key /rails/config/ai_private_keys.yml.enc && \
    rm -rf /rails/storage/ai_private_keys*

FROM base AS web-final

COPY --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --from=app-export /rails /rails

# /data is where the compose file mounts the SQLite volume. It must exist and be
# owned by `rails` before the volume is mounted, otherwise the unprivileged
# process cannot create the database files.
RUN useradd rails --create-home --shell /bin/bash && \
    mkdir -p /data && \
    chown -R rails:rails db log storage tmp /data
USER rails:rails

ENTRYPOINT ["/rails/bin/docker-entrypoint"]
EXPOSE 80
# The thruster gem's executable is `thrust`, not `thruster` — ./bin/thruster
# does not exist and the container cannot start with it.
CMD ["./bin/thrust", "./bin/rails", "server"]

FROM base AS worker-final

COPY --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --from=build /rails /rails

# /data holds the shared SQLite volume (same as web); /keys is a dedicated,
# worker-only volume mount point for the private-key SQLite database — see
# docker-compose.yml's `worker-keys` volume. Only the worker container ever
# mounts it, so the private-key database never coexists with the web tier.
RUN useradd rails --create-home --shell /bin/bash && \
    mkdir -p /data /keys && \
    chown -R rails:rails db log storage tmp /data /keys
USER rails:rails

ENTRYPOINT ["/rails/bin/docker-entrypoint"]
CMD ["bundle", "exec", "rake", "solid_queue:start"]
