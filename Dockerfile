# https://github.com/dbeaver/cloudbeaver/wiki/Run-Docker-Container
FROM dbeaver/cloudbeaver:latest 

ARG BUILD_DATE
ARG BUILD_IMAGE

COPY helx /helx
RUN chmod +x /helx/helx-init.sh

RUN groupadd cloudbeaver
RUN useradd -ms /bin/sh -g 0 cloudbeaver
RUN usermod -aG 0 cloudbeaver
# RUN chown root:cloudbeaver /etc/passwd
RUN chmod g+w /etc/passwd && chmod g+w /etc/group
RUN chown -R cloudbeaver ./ /home /helx /opt/cloudbeaver

USER cloudbeaver
ENV NB_USER=joshua-seals
WORKDIR /helx

ENTRYPOINT [ "./helx-init.sh" ]

LABEL org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.title="cloudbeaver" \
      org.opencontainers.image.authors="Joshua Seals" \
      org.opencontainers.image.source="https://github.com/helxplatform/cloudbeaver" \
      org.opencontainers.image.revision="${BUILD_IMAGE}" \
      org.opencontainers.image.vendor="Renci"
      
# Persistence space
# /opt/cloudbeaver/workspace

# FROM alpine:latest

# RUN apk update && apk add bash

# ENV JAVA_HOME=/opt/java/openjdk
# COPY --from=eclipse-temurin:17-alpine $JAVA_HOME $JAVA_HOME
# ENV PATH="${JAVA_HOME}/bin:${PATH}"

# ENV CLOUDBEAVER_HOME="/opt/cloudbeaver"
# COPY --from=dbeaver/cloudbeaver:latest $CLOUDBEAVER_HOME $CLOUDBEAVER_HOME

# WORKDIR "/opt/cloudbeaver"

# RUN chmod +x run-server.sh

# ENTRYPOINT ["./run-server.sh"]
