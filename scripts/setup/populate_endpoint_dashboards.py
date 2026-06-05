import json
import random
import requests
from datetime import datetime, timedelta, timezone

ES_LOGSTASH = 'http://localhost:9200/logstash-mock-data/_doc/'

def now_ts():
    return (datetime.now(timezone.utc) - timedelta(minutes=random.randint(0, 15))).isoformat()

def inject_ransomware_files():
    for _ in range(500):
        doc = {
            '@timestamp': now_ts(),
            'tags': ['endpoint_logs'],
            'agent': {'hostname': 'win-lab-01'},
            'winlog': {
                'channel': 'Microsoft-Windows-Sysmon/Operational',
                'event_id': 11,
                'event_data': {
                    'TargetFilename': f'C:\\\\Users\\\\tjlam\\\\Documents\\\\file_{random.randint(1,1000)}.txt.encrypted',
                    'Image': 'C:\\\\Windows\\\\Temp\\\\malware.exe'
                }
            },
            'event': {'category': 'file', 'type': 'creation', 'action': 'file_create'}
        }
        requests.post(ES_LOGSTASH, json=doc)

def inject_reboots():
    for _ in range(10):
        doc = {
            '@timestamp': now_ts(),
            'tags': ['endpoint_logs'],
            'agent': {'hostname': random.choice(['win-lab-01', 'win-lab-02'])},
            'winlog': {
                'channel': 'System',
                'event_id': 6005,
                'provider_name': 'EventLog'
            },
            'event': {'action': 'system-boot', 'outcome': 'success'}
        }
        requests.post(ES_LOGSTASH, json=doc)

def inject_failed_ssh():
    countries = [('RU', 55.0, 37.0), ('CN', 35.0, 105.0), ('KP', 40.0, 127.0)]
    for _ in range(300):
        country, lat, lon = random.choice(countries)
        doc = {
            '@timestamp': now_ts(),
            'tags': ['endpoint_logs'],
            'log': {'file': {'path': '/var/log/auth.log'}},
            'process': {'name': 'sshd'},
            'event': {'outcome': 'failure', 'action': 'ssh_login'},
            'system': {'auth': {'method': 'password'}},
            'user': {'name': 'root'},
            'source': {
                'ip': f'{random.randint(1, 255)}.{random.randint(1, 255)}.{random.randint(1, 255)}.{random.randint(1, 255)}',
                'port': random.randint(30000, 60000),
                'geo': {'country_iso_code': country, 'location': {'lat': lat, 'lon': lon}}
            }
        }
        requests.post(ES_LOGSTASH, json=doc)

if __name__ == '__main__':
    print('Injecting highly specific endpoint mock data (Ransomware, Reboots, Failed SSH)...')
    inject_ransomware_files()
    inject_reboots()
    inject_failed_ssh()
    print('Done.')
