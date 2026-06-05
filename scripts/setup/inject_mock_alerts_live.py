import json
import random
import requests
from datetime import datetime, timedelta, timezone

# Injecting into the actual default alerts index that Kibana Security relies on
ES_URL = 'http://localhost:9200/.internal.alerts-security.alerts-default-000001/_doc/'

def generate_alert(i):
    now = datetime.now(timezone.utc)
    event_time = now - timedelta(hours=random.randint(1, 48), minutes=random.randint(0, 59))
    alert_time = event_time + timedelta(minutes=random.randint(5, 45))
    
    nist_tags = ['NIST:Identify', 'NIST:Protect', 'NIST:Detect', 'NIST:Respond', 'NIST:Recover']
    attack_tags = ['attack.credential_access', 'attack.t1003.001', 'attack.command_and_control', 'attack.t1105', 'attack.persistence', 'attack.defense_evasion']
    
    tags = [random.choice(nist_tags), random.choice(attack_tags)]
    
    doc = {
        '@timestamp': event_time.isoformat(),
        'kibana.alert.start': alert_time.isoformat(),
        'tags': tags,
        'kibana.alert.rule.name': f'Mock Rule {random.randint(1, 10)}',
        'kibana.alert.workflow_status': random.choice(['automated', 'manual', 'acknowledged']),
        'event.kind': 'alert',
        'event.module': 'security_solution'
    }
    return doc

def main():
    print('Injecting mock alerts into live ES Index...')
    for i in range(100):
        doc = generate_alert(i)
        resp = requests.post(ES_URL, json=doc)
        if i % 10 == 0:
            print(f'Inserted {i} alerts... Status: {resp.status_code}')
            
if __name__ == '__main__':
    main()
