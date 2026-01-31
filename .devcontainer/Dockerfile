FROM mcr.microsoft.com/vscode/devcontainers/javascript-node:18

# Install Flutter
RUN wget -O flutter.tar.xz https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.16.0-stable.tar.xz \
    && tar xf flutter.tar.xz \
    && mv flutter /opt/ \
    && rm flutter.tar.xz

# Set Flutter environment variables
ENV PATH="/opt/flutter/bin:${PATH}"
ENV FLUTTER_ROOT="/opt/flutter"

# Install additional dependencies for Flutter
RUN apt-get update && apt-get install -y \
    curl \
    git \
    unzip \
    xz-utils \
    zip \
    libglu1-mesa \
    && rm -rf /var/lib/apt/lists/*

# Run Flutter doctor to verify installation
RUN flutter doctor

# Set working directory
WORKDIR /workspaces

# Install Node.js dependencies for backend
RUN npm install -g nodemon

# Expose ports for backend and frontend
EXPOSE 3000 8080 5000
