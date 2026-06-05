import json
import random
import requests
from datetime import datetime, timedelta, timezone

ES_LOGSTASH = 'http://localhost:9200/logstash-dynamic-2026/_doc/'

def now_ts():
    return (datetime.now(timezone.utc) - timedelta(minutes=random.randint(0, 10))).isoformat()

def inject_endpoint_dynamic():
    # Process Tree
    for _ in range(100):
        doc = {
            '@timestamp': now_ts(),
            'tags': ['endpoint_logs'],
            'agent': {'hostname': 'win-lab-01'},
            'process': {
                'executable': f'C:\\\\Windows\\\\System32\\\\{random.choice(["cmd.exe", "powershell.exe"])}',
                'parent': {'name': random.choice(['winword.exe', 'excel.exe', 'services.exe'])}
            }
        }
        requests.post(ES_LOGSTASH, json=doc)

    # Sigma
    for _ in range(40):
        doc = {
            '@timestamp': now_ts(),
            'tags': ['endpoint_logs', f'sigma_{random.choice(["lsass_dump", "powershell_encoded", "bitsadmin"])}'],
            'agent': {'hostname': 'win-lab-01'}
        }
        requests.post(ES_LOGSTASH, json=doc)

if __name__ == '__main__':
    print('Injecting dynamic Endpoint mock data...')
    inject_endpoint_dynamic()
    print('Done.')
