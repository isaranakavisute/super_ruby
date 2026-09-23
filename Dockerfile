# Specify base image (keep in sync with .ruby-version)
FROM ruby:3.4.10-slim

WORKDIR /rails-app

# Set up env (before precompile so assets are built for production)
ENV RAILS_ENV=production \
    BUNDLE_DEPLOYMENT=1 \
    BUNDLE_PATH=/usr/local/bundle \
    BUNDLE_WITHOUT=development:test \
    PORT=4000 \
    LD_PRELOAD=/usr/local/lib/libjemalloc.so

# Install utilities and build dependencies, and link jemalloc (loaded via LD_PRELOAD) to a fixed path
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
      build-essential git libyaml-dev pkg-config sqlite3 libjemalloc2 nano && \
    ln -s /usr/lib/$(uname -m)-linux-gnu/libjemalloc.so.2 /usr/local/lib/libjemalloc.so && \
    rm -rf /var/lib/apt/lists/*

# Install dependencies (copied first so this layer is cached between code changes)
COPY Gemfile Gemfile.lock ./
RUN bundle install && \
    rm -rf ~/.bundle "${BUNDLE_PATH}"/ruby/*/cache

# Add application code
COPY . .

# Precompile bootsnap and assets - assets only required for non-API apps
RUN bundle exec bootsnap precompile app/ lib/ && \
    SECRET_KEY_BASE_DUMMY=1 ./bin/rails assets:precompile

# Run as a non-root user
RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash && \
    chown -R rails:rails db log storage tmp
USER 1000:1000

ENTRYPOINT ["/rails-app/bin/docker-entrypoint"]

# Expose port (Puma listens on $PORT)
EXPOSE 4000

# Run server when container starts. Rails binds to 0.0.0.0 outside development, and the command
# must end in "./bin/rails server" for bin/docker-entrypoint to run db:prepare first.
CMD ["./bin/rails", "server"]
