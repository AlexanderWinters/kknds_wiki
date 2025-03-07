#!/bin/bash
cd /opt/docusaurus
git pull origin main  # or your deployment branch
npm install
npm run build