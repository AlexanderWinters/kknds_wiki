#!/bin/bash

set -a
source .env
set +a

cd $GIT_PATH

git reset --hard
git fetch origin
git pull origin main

cd $WIKI_PATH
npm install
npm run build
