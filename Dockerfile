# Use the Eclipse Temurin JRE 8 image
# see https://github.com/airsonic-advanced/airsonic-advanced/blob/master/install/docker/Dockerfile
#FROM eclipse-temurin:8-jre
#FROM eclipse-temurin:8-jre-ubi9-minimal
FROM adoptopenjdk/openjdk8:alpine

# Set environment variables for Subsonic
ENV SUBSONIC_VERSION=6.1.6 \
    SUBSONIC_HOME=/var/subsonic

# Define build arguments for dynamic user/group IDs
ARG USER_ID=1000
ARG GROUP_ID=1000

# Install dependencies (FFmpeg, codecs, etc.)
RUN apk add --no-cache \
    ffmpeg \
    x264 \
    x265 \
    lame \
    bash

# Create Subsonic group and user only if they don't exist
RUN if getent passwd 1000; then \
        existing_user=$(getent passwd 1000 | cut -d: -f1); \
        echo "Renaming existing user $existing_user"; \
        deluser "$existing_user"; \
    fi; \
    if ! getent group 1000; then \
        addgroup -g 1000 subsonic; \
    fi; \
    adduser -D -u 1000 -G subsonic subsonic

# Create necessary directories and set permissions
RUN mkdir -p ${SUBSONIC_HOME} /var/music /var/playlists /var/podcasts /opt/subsonic \
    && chown -R ${USER_ID}:${GROUP_ID} ${SUBSONIC_HOME} /var/music /var/playlists /var/podcasts

# Set working directory
WORKDIR /opt/subsonic

# Download and install Subsonic
#ADD https://sourceforge.net/projects/subsonic/files/subsonic/${SUBSONIC_VERSION}/subsonic-${SUBSONIC_VERSION}-standalone.tar.gz /tmp/subsonic.tar.gz
#ADD https://s3-eu-west-1.amazonaws.com/subsonic-public/download/subsonic-6.1.6-standalone.tar.gz /tmp/subsonic.tar.gz
RUN wget -O /tmp/subsonic.tar.gz https://s3-eu-west-1.amazonaws.com/subsonic-public/download/subsonic-${SUBSONIC_VERSION}-standalone.tar.gz
RUN tar -tzf /tmp/subsonic.tar.gz

RUN tar -xzf /tmp/subsonic.tar.gz -C /opt/subsonic \
    && chmod +x /opt/subsonic/subsonic.sh \
    && rm /tmp/subsonic.tar.gz

# Add the entrypoint script
COPY entrypoint.sh /opt/subsonic/entrypoint.sh
RUN chmod +x /opt/subsonic/entrypoint.sh

# Expose ports and volumes
EXPOSE 4040
VOLUME ["/var/music", "/var/playlists", "/var/podcasts", "${SUBSONIC_HOME}"]

# Use the entrypoint script to set default values and run the app
ENTRYPOINT ["/opt/subsonic/entrypoint.sh"]

