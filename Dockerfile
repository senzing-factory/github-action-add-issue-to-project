# Container image that runs your code
FROM alpine:3.22.0

RUN apk add --no-cache --no-progress curl jq

# Copies your code file from your action repository to the filesystem path `/` of the container
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x entrypoint.sh

HEALTHCHECK CMD git --version || exit 1

USER 1001

# Code file to execute when the docker container starts up (`entrypoint.sh`)
ENTRYPOINT ["/entrypoint.sh"]
