#!/bin/bash
cd /opt/kknds_wiki/wiki && npm run serve -- --port 4000 --host 0.0.0.0 --no-open &
cd /opt/kknds_wiki/webhook && . venv/bin/activate && python app.py &
wait
