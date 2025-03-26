#!/bin/bash
cd /opt/live/kknds_wiki

git reset --hard
git clean -fd
git fetch origin
git pull origin main

cd /opt/live/kknds_wiki/wiki
npm install
npm run build
