#!/bin/bash
cd /opt/kknds_wiki

git reset --hard
git clean -fd
git fetch origin
git pull origin main

cd /opt/kknds_wiki/wiki
npm install
npm run build