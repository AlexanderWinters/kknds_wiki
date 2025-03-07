#!/bin/bash
cd /opt/docusaurus && npm run serve -- --host 0.0.0.0 --no-open &
cd /opt/webhook && . venv/bin/activate && python webhook.py &
wait
