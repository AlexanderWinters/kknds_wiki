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

WORKDIR /opt/
RUN git clone https://github.com/AlexanderWinters/kknds_wiki.git .
RUN npm ci
RUN npm run build

#WEBHOOK SETUP
WORKDIR /opt/webhook/
COPY webhook/requirements.txt .
COPY webhook/webhook.py .
COPY webhook/deploy.sh .
RUN python3 -m venv venv && \
    . venv/bin/activate && \
    pip install --no-cache-dir -r requirements.txt
RUN chmod +x /opt/webhook/deploy.sh

COPY start.sh /opt/
RUN chmod +x /opt/start.sh

EXPOSE 3000 4000
CMD ["/opt/start.sh"]