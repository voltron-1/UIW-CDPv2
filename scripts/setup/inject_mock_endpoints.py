import json
import random
import requests
from datetime import datetime, timedelta, timezone

ES_URL = 'http://localhost:9200/logstash-security-mock/_doc/'

def generate_endpoint_event(i):
    now = datetime.now(timezone.utc)
    event_time = now - timedelta(hours=random.randint(1, 48), minutes=random.randint(0, 59))
    
    hosts = ['win-lab-01', 'win-lab-02', 'db-server-01']
    users = ['tjlam', 'admin', 'system']
    processes = ['rundll32.exe', 'powershell.exe', 'cmd.exe', 'svchost.exe']
    
    doc = {
        '@timestamp': event_time.isoformat(),
        'agent': {'hostname': random.choice(hosts)},
        'host': {'name': random.choice(hosts)},
        'user': {'name': random.choice(users)},
        'process': {
            'executable': f'C:\\\\Windows\\\\System32\\\\{random.choice(processes)}',
            'name': random.choice(processes)
        },
        'event': {'category': 'process', 'type': 'start', 'outcome': 'success'},
        'tags': ['endpoint_logs']
    }
    
    # Simulate a Sigma rule hit
    if random.random() < 0.1:
        doc['tags'].append('sigma_hit')
        doc['rule'] = {'name': 'Suspicious PowerShell Execution'}
        
    return doc

def main():
    print('Injecting mock endpoint logs into Elasticsearch...')
    for i in range(200):
        doc = generate_endpoint_event(i)
        resp = requests.post(ES_URL, json=doc)
        if i % 20 == 0:
            print(f'Inserted {i} events... Status: {resp.status_code}')
            
if __name__ == '__main__':
    main()
