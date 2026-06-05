import json
import random
import requests
from datetime import datetime, timedelta, timezone

ES_LOGSTASH = 'http://localhost:9200/logstash-dynamic-2026/_doc/'
ES_SOAR = 'http://localhost:9200/soar-actions-dynamic-2026/_doc/'

def now_ts():
    return (datetime.now(timezone.utc) - timedelta(minutes=random.randint(0, 15))).isoformat()

def inject_logstash_exec_metrics():
    # Inject 50 Critical incidents and MITRE/NIST mappings
    for i in range(150):
        is_critical = i < 50
        tags = ['CRITICAL_THREAT'] if is_critical else []
        
        severity = random.choice(['critical', 'high', 'medium', 'low'])
        if is_critical:
            severity = 'critical'
            
        nist = random.choice(['Identify', 'Protect', 'Detect', 'Respond', 'Recover'])
        
        techniques = [
            {'id': 'T1059', 'name': 'Command and Scripting Interpreter'},
            {'id': 'T1110', 'name': 'Brute Force'},
            {'id': 'T1003', 'name': 'OS Credential Dumping'},
            {'id': 'T1071', 'name': 'Application Layer Protocol'}
        ]
        tech = random.choice(techniques)
        
        doc = {
            '@timestamp': now_ts(),
            'tags': tags,
            'event': {'severity': severity},
            'nist': {'function': nist},
            'threat': {
                'technique': {
                    'id': tech['id'],
                    'name': tech['name']
                }
            }
        }
        requests.post(ES_LOGSTASH, json=doc)

def inject_soar_actions():
    # Inject 40 automated and manual SOAR actions
    for i in range(40):
        automated = i < 30  # 30 automated, 10 manual
        action_type = random.choice(['quarantine_mac', 'block_ip']) if automated else 'analyst_review'
        
        doc = {
            '@timestamp': now_ts(),
            'action': {'type': action_type},
            'response': {'automated': "True" if automated else "False"}
        }
        requests.post(ES_SOAR, json=doc)

if __name__ == '__main__':
    print('Injecting Executive Dashboard mock data...')
    inject_logstash_exec_metrics()
    inject_soar_actions()
    print('Done.')
