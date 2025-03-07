#!/bin/bash
cd /opt/kknds_wiki
git pull origin main  # or your deployment branch
cd /opt/kknds_wiki/wiki
npm install
npm run build