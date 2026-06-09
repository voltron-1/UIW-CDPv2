#!/bin/bash
cd /home/tjlam/projects/UIW-Cyber-Defence-Platform/scripts/setup
source ai_agent/.venv/bin/activate
python3 export_data_views.py
cd /home/tjlam/projects/UIW-Cyber-Defence-Platform
git add configs/server/kibana_data_views_final.ndjson
git commit -m "Export Kibana Data Views including dynamic patterns"
git push
