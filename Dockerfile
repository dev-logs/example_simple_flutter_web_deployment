FROM ubuntu:16.04 as builder
USER root
# Install Flutter build-time dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends git wget unzip libglu1-mesa lib32stdc++6 ca-certificates curl tar \
    xz-utils clang cmake ninja-build pkg-config libgtk-3-dev && \
    rm -rf /var/lib/apt/lists/*
WORKDIR /
# Download and install flutter 3.13.8, feel free to change the version as needed
RUN curl https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.13.8-stable.tar.xz -o flutter-sdk.tar.xz
RUN tar xf flutter-sdk.tar.xz && rm flutter-sdk.tar.xz
ENV PATH="$PATH:/flutter/bin"
RUN flutter config --no-analytics --enable-web && \
    flutter precache && \
    flutter doctor && \
    rm -rf .pub_cache
RUN dart pub global activate protoc_plugin
ENV PATH="$PATH":"/root/.pub-cache/bin/"
# Copy your project into Docker and build the flutter web
WORKDIR /src
COPY . .
RUN flutter build web --release

# Now we switch to the running phase
# In this phase we simply do:
# - Install nginx to use as WebServer
# - Copy the build/web folder from builder to runner
# - Restart nginx everytime we start the container
FROM ubuntu:16.04 as runner
USER root
WORKDIR /app
RUN apt-get update && \
    apt-get install -y \
    curl unzip nginx && \
    rm -rf /var/lib/apt/lists/*
COPY --from=builder /src/build/web .
COPY nginx.conf /etc/nginx/sites-available/default
RUN service nginx stop
ENTRYPOINT ["/bin/bash", "-c", "echo 'Start nginx...'; nginx -g 'daemon off;'"]
