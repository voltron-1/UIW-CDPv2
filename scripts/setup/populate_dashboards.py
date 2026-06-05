import json
import random
import requests
from datetime import datetime, timedelta, timezone

ES_LOGSTASH = 'http://localhost:9200/logstash-mock-data/_doc/'
ES_ALERTS = 'http://localhost:9200/.internal.alerts-security.alerts-default-000001/_doc/'
ES_SOAR = 'http://localhost:9200/soar-actions-mock/_doc/'

def now_ts():
    return (datetime.now(timezone.utc) - timedelta(minutes=random.randint(0, 15))).isoformat()

def inject_network():
    for _ in range(500):
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
        requests.post(ES_LOGSTASH, json=doc)

def inject_endpoint():
    for _ in range(200):
        doc = {
            '@timestamp': now_ts(),
            'tags': ['endpoint_logs'],
            'agent': {'hostname': random.choice(['win-lab-01', 'win-lab-02', 'db-server-01'])},
            'host': {'name': random.choice(['win-lab-01', 'win-lab-02', 'db-server-01'])},
            'user': {'name': random.choice(['tjlam', 'admin', 'system'])},
            'process': {
                'executable': f'C:\\Windows\\System32\\{random.choice(["rundll32.exe", "powershell.exe", "cmd.exe"])}',
                'name': random.choice(['rundll32.exe', 'powershell.exe', 'cmd.exe']),
                'args': '-NoProfile -Command Invoke-WebRequest',
                'parent': {'name': 'explorer.exe'}
            },
            'event': {'category': 'process', 'type': 'start', 'outcome': 'success'}
        }
        requests.post(ES_LOGSTASH, json=doc)

def inject_alerts():
    nist = ['NIST:Identify', 'NIST:Protect', 'NIST:Detect', 'NIST:Respond', 'NIST:Recover']
    mitre = ['attack.credential_access', 'attack.t1003.001', 'attack.command_and_control', 'attack.defense_evasion']
    for _ in range(100):
        ts = datetime.now(timezone.utc) - timedelta(minutes=random.randint(1, 15))
        alert_ts = ts + timedelta(minutes=random.randint(1, 5))
        doc = {
            '@timestamp': ts.isoformat(),
            'kibana.alert.start': alert_ts.isoformat(),
            'tags': [random.choice(nist), random.choice(mitre)],
            'kibana.alert.rule.name': f'Mock Alert {random.randint(1,5)}',
            'kibana.alert.workflow_status': random.choice(['automated', 'manual', 'acknowledged']),
            'event.kind': 'alert'
        }
        requests.post(ES_ALERTS, json=doc)

def inject_soar():
    for _ in range(50):
        doc = {
            '@timestamp': now_ts(),
            'action': 'quarantine',
            'target_mac': 'AA:BB:CC:DD:EE:FF',
            'status': 'success'
        }
        requests.post(ES_SOAR, json=doc)

if __name__ == '__main__':
    print('Injecting dense mock data for last 15 minutes...')
    inject_network()
    inject_endpoint()
    inject_alerts()
    inject_soar()
    print('Done.')
