FROM openjdk:8-jre-alpine


ENV TZ="GMT" \
    PATH="/sqlcl_bin/sqlcl/bin:${PATH}" \
    DB_TNS=${DB_TNS:-localhost} \
    SYS_USER=${SYS_USER:-sys} \
    ENV="/.ashrc"

# Wen need that on build!
ARG DOWNLOAD_URL
ONBUILD RUN if [ -z "${DOWNLOAD_URL}" ]; then echo "DOWNLOAD_URL NOT SET - ERROR"; exit 1; else : ; fi

ARG FILE_SQLCL

# all installation files
COPY scripts /scripts

# Copy files
COPY _binaries /tmp

RUN chmod +x /scripts/install-sqlcl.sh; sync && \
  chmod +x /scripts/entrypoint.sh; sync && \
  apk update && \
  apk upgrade && \
  apk add --update ca-certificates && \
    update-ca-certificates && \
  # bash is required by sqlcl
  apk add --no-cache bash git openssh curl && \
  # for tput which is required by sqlcl
  apk add ncurses && \
  rm /var/cache/apk/* && \
  echo "#!/bin/bash" > "$ENV" && \
  echo "" >> "$ENV" && \
  echo "echo 'ashrc'" >> "$ENV" && \
  echo "alias ll=\"ls -la\"" >> "$ENV" && \
  mkdir /sqlcl; sync && \
  #mv /tmp/entrypoint.sh /sqlcl; sync && \
  #ls -la /sqlcl; sync && \
  chmod +x "$ENV" && \
  /scripts/install-sqlcl.sh

# Define out entrypoint
ENTRYPOINT ["/scripts/entrypoint.sh"]
CMD [""]