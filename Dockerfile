# Use the Eclipse Temurin JRE 8 image
# see https://github.com/airsonic-advanced/airsonic-advanced/blob/master/install/docker/Dockerfile
FROM eclipse-temurin:8-jre

# Set environment variables for Subsonic
ENV SUBSONIC_VERSION=6.1.6 \
    SUBSONIC_HOME=/var/subsonic

# Define build arguments for dynamic user/group IDs
ARG USER_ID=1000
ARG GROUP_ID=1000

# Install dependencies (FFmpeg, codecs, etc.)
RUN apt-get update \
    && apt-get install -y \
       ffmpeg \
       x264 \
       x265 \
       lame \
       xmp \
       bash \
       fonts-dejavu \
       gosu \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Create Subsonic group and user only if they don't exist
#RUN getent group ${GROUP_ID} || groupadd -g ${GROUP_ID} subsonic \
#    && id -u ${USER_ID} || useradd -m -u ${USER_ID} -g ${GROUP_ID} subsonic

#RUN groupadd -g ${GROUP_ID} subsonic || true \
#    && useradd -m -u ${USER_ID} -g subsonic subsonic || true
#RUN if ! getent group ${GROUP_ID}; then groupadd -g ${GROUP_ID} subsonic; fi \
#    && if ! id -u ${USER_ID}; then useradd -m -u ${USER_ID} -g ${GROUP_ID} subsonic; fi
#RUN if getent passwd ${USER_ID}; then \
##      existing_user=$(getent passwd ${USER_ID} | cut -d: -f1) && \
#      usermod -l "${existing_user}_backup" "${existing_user}"; \
#    fi \
#    && if ! getent group ${GROUP_ID}; then groupadd -g ${GROUP_ID} subsonic; fi \
#    && useradd -m -u ${USER_ID} -g ${GROUP_ID} subsonic
RUN if getent passwd ${USER_ID}; then \
      existing_user=$(getent passwd ${USER_ID} | cut -d: -f1); \
      echo "Renaming existing user $existing_user"; \
      usermod -l "${existing_user}_backup" -u $((USER_ID + 1)) "${existing_user}" || exit 1; \
    fi \
    && if ! getent group ${GROUP_ID}; then groupadd -g ${GROUP_ID} subsonic; fi \
    && useradd -m -u ${USER_ID} -g ${GROUP_ID} subsonic

# Verify user creation
#RUN id subsonic && cat /etc/passwd

# Create necessary directories and set permissions
RUN mkdir -p ${SUBSONIC_HOME} /var/music /var/playlists /var/podcasts /opt/subsonic \
    && chown -R ${USER_ID}:${GROUP_ID} ${SUBSONIC_HOME} /var/music /var/playlists /var/podcasts

# Set working directory
#WORKDIR ${SUBSONIC_HOME}
WORKDIR /opt/subsonic

# Download and install Subsonic
#ADD https://sourceforge.net/projects/subsonic/files/subsonic/${SUBSONIC_VERSION}/subsonic-${SUBSONIC_VERSION}-standalone.tar.gz /tmp/subsonic.tar.gz
#ADD https://s3-eu-west-1.amazonaws.com/subsonic-public/download/subsonic-6.1.6-standalone.tar.gz /tmp/subsonic.tar.gz
RUN wget -O /tmp/subsonic.tar.gz https://s3-eu-west-1.amazonaws.com/subsonic-public/download/subsonic-6.1.6-standalone.tar.gz
RUN tar -tzf /tmp/subsonic.tar.gz
#RUN ls -la /opt/subsonic
RUN tar -xzf /tmp/subsonic.tar.gz -C /opt/subsonic \
    && chmod +x /opt/subsonic/subsonic.sh \
    && rm /tmp/subsonic.tar.gz

#RUN ls -la /opt/subsonic
#RUN curl -L https://s3-eu-west-1.amazonaws.com/subsonic-public/download/subsonic-$%7BSUBSONIC_VERSION%7D-standalone.tar.gz -o /tmp/subsonic.tar.gz \
#    && tar -xzf /tmp/subsonic.tar.gz -C ${SUBSONIC_HOME} --strip-components=1 \
#    && rm /tmp/subsonic.tar.gz

#RUN tar -xzf /tmp/subsonic.tar.gz -C ${SUBSONIC_HOME} --strip-components=1 \
#    && rm /tmp/subsonic.tar.gz

# Add the entrypoint script
COPY entrypoint.sh /opt/subsonic/entrypoint.sh
RUN chmod +x /opt/subsonic/entrypoint.sh

# Expose ports and volumes
EXPOSE 4040
VOLUME ["/var/music", "/var/playlists", "/var/podcasts", "${SUBSONIC_HOME}"]

# Use the entrypoint script to set default values and run the app
ENTRYPOINT ["/opt/subsonic/entrypoint.sh"]

