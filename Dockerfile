# syntax=docker/dockerfile:1

FROM node:lts

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    python3 \
    python3-pip \
    python3-venv \
    bash \
    git \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
## Disable colour output from yarn to make logs easier to read.
ENV FORCE_COLOR=0
## Enable corepack.
RUN corepack enable

WORKDIR /opt
RUN git clone https://github.com/AlexanderWinters/kknds_wiki.git

COPY /opt/kknds_wiki/start.sh /opt/
RUN chmod +x /opt/start.sh

#BUILD THE WIKI PAGE
WORKDIR /opt/kknds_wiki/wiki
RUN npm ci
RUN npm run build

#WEBHOOK SETUP
WORKDIR /opt/kknds_wiki/webhook
RUN python3 -m venv venv && \
    . venv/bin/activate && \
    pip install --no-cache-dir -r requirements.txt
RUN chmod +x deploy.sh



EXPOSE 3000 4000
CMD ["/opt/start.sh"]