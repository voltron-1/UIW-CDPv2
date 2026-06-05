import json
import random
import requests
from datetime import datetime, timedelta, timezone

ES_LOGSTASH = 'http://localhost:9200/logstash-security-2026.06.04/_doc/'

def now_ts():
    return (datetime.now(timezone.utc) - timedelta(minutes=random.randint(0, 10))).isoformat()

def inject_network():
    for _ in range(300):
        doc = {
            '@timestamp': now_ts(),
            'tags': ['network_logs'],
            'source': {
                'ip': f'10.18.81.{random.randint(10, 200)}',
                'port': random.randint(1024, 65535),
                'mac': '00:11:22:33:44:55',
                'geo': {'location': {'lat': 34.0, 'lon': -118.0}, 'country_iso_code': 'US'}
            },
            'destination': {
                'ip': f'{random.randint(1, 255)}.{random.randint(1, 255)}.{random.randint(1, 255)}.{random.randint(1, 255)}',
                'port': random.choice([80, 443, 53, 22, 3389]),
                'mac': 'AA:BB:CC:DD:EE:FF',
                'geo': {'location': {'lat': 51.5, 'lon': -0.1}, 'country_iso_code': 'GB'}
            },
            'network': {
                'protocol': random.choice(['http', 'dns', 'tls', 'ssh']),
                'transport': random.choice(['tcp', 'udp'])
            }
        }
        if doc['network']['protocol'] == 'dns':
            doc['dns'] = {
                'question': {'name': random.choice(['google.com', 'malicious.xyz', 'github.com']), 'type': 'A'},
                'response': {'code': 'NOERROR'}
            }
        elif doc['network']['protocol'] == 'http':
            doc['http'] = {
                'request': {'method': random.choice(['GET', 'POST'])},
                'response': {'status_code': random.choice([200, 404, 500])}
            }
        elif doc['network']['protocol'] == 'tls':
            doc['tls'] = {
                'client': {'server_name': random.choice(['api.github.com', 'evil-c2.net'])},
                'cipher': random.choice(['TLS_AES_128_GCM_SHA256', 'TLS_AES_256_GCM_SHA384'])
            }
        requests.post(ES_LOGSTASH, json=doc)

def inject_endpoint_fixes():
    # 1. System Reboots (1074)
    for _ in range(15):
        doc = {
            '@timestamp': now_ts(),
            'tags': ['endpoint_logs'],
            'agent': {'hostname': random.choice(['win-lab-01', 'win-lab-02'])},
            'winlog': {
                'channel': 'System',
                'event_id': 1074,
                'provider_name': 'EventLog'
            }
        }
        requests.post(ES_LOGSTASH, json=doc)

    # 2. Sigma Rule Hits
    for _ in range(40):
        doc = {
            '@timestamp': now_ts(),
            'tags': ['endpoint_logs', f'sigma_{random.choice(["lsass_dump", "powershell_encoded", "bitsadmin"])}'],
            'agent': {'hostname': 'win-lab-01'}
        }
        requests.post(ES_LOGSTASH, json=doc)

    # 3. Process Tree Anomalies
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

if __name__ == '__main__':
    print('Injecting missing Network and Endpoint mock data into live logstash index...')
    inject_network()
    inject_endpoint_fixes()
    print('Done.')
