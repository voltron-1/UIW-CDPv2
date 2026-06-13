import requests
import json

url = "http://localhost:5601/api/saved_objects/_export"
headers = {"kbn-xsrf": "true"}
data = {"type": ["index-pattern"]}

response = requests.post(url, headers=headers, json=data)

output_file = "/home/tjlam/projects/UIW-Cyber-Defence-Platform/configs/server/kibana_data_views_final.ndjson"
with open(output_file, "w") as f:
    f.write(response.text)

print(f"Exported data views to {output_file}")
