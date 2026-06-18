#!/bin/bash
cd /home/tjlam/projects/UIW-CDPv2/scripts/setup
source ai_agent/.venv/bin/activate
python3 export_data_views.py
cd /home/tjlam/projects/UIW-CDPv2
git add configs/server/kibana_data_views_final.ndjson
git commit -m "Export Kibana Data Views including dynamic patterns"
git push
