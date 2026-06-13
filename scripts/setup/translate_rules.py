#!/usr/bin/env python3
import os
import yaml
import json
from pathlib import Path

RULES_DIR = Path("/home/tjlam/projects/UIW-Cyber-Defence-Platform/rules/sigma")
OUTPUT_DIR = Path("/home/tjlam/projects/UIW-Cyber-Defence-Platform/rules/elastic_watcher")

REQUIRED_FIELDS = ['title', 'id', 'status', 'logsource', 'detection']

def load_rules():
    rules = []
    for filepath in RULES_DIR.glob("*.yml"):
        with open(filepath, 'r') as f:
            try:
                rule = yaml.safe_load(f)
                rules.append((filepath.name, rule))
            except yaml.YAMLError as e:
                print(f"[!] Error parsing {filepath.name}: {e}")
    return rules

def validate_rule(filename, rule):
    missing = [field for field in REQUIRED_FIELDS if field not in rule]
    if missing:
        print(f"[FAIL] {filename} is missing fields: {', '.join(missing)}")
        return False
    print(f"[PASS] {filename} is valid.")
    return True

def convert_to_elasticsearch(filename, rule):
    # This is a basic mock conversion to Elasticsearch NDJSON format for Detection Rules
    es_rule = {
        "id": rule.get('id'),
        "rule_id": rule.get('id'),
        "name": rule.get('title'),
        "description": rule.get('description', ''),
        "enabled": rule.get('status') == 'experimental',
        "severity": rule.get('level', 'low'),
        "risk_score": 50 if rule.get('level') == 'high' else 21,
        "query": f"tags: \"{rule.get('tags', [''])[0]}\"", # Placeholder query logic
        "type": "query",
        "index": ["logstash-*"],
        "tags": rule.get('tags', [])
    }
    return es_rule

def generate_attack_matrix(rules):
    tactics = {}
    for filename, rule in rules:
        for tag in rule.get('tags', []):
            if tag.startswith('attack.'):
                tag_name = tag.split('.')[1]
                if tag_name not in tactics:
                    tactics[tag_name] = []
                tactics[tag_name].append(rule.get('title'))
    return tactics

def main():
    print("--- Sigma Rule Validation & Translation ---")
    rules = load_rules()
    
    valid_rules = []
    for filename, rule in rules:
        if validate_rule(filename, rule):
            valid_rules.append((filename, rule))

    print(f"\nSuccessfully validated {len(valid_rules)}/{len(rules)} rules.")
    
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    print("\n--- Translating to Elasticsearch NDJSON ---")
    for filename, rule in valid_rules:
        es_rule = convert_to_elasticsearch(filename, rule)
        output_name = filename.replace('.yml', '.ndjson')
        output_path = OUTPUT_DIR / output_name
        with open(output_path, 'w') as f:
            f.write(json.dumps(es_rule) + '\n')
        print(f"Translated -> {output_name}")

    print("\n--- Generating ATT&CK Matrix Data ---")
    matrix = generate_attack_matrix(valid_rules)
    for tactic, rule_titles in matrix.items():
        print(f"Tactic: {tactic.upper()}")
        for title in rule_titles:
            print(f"  - {title}")

    # Output markdown matrix
    matrix_md_path = Path("/home/tjlam/projects/UIW-Cyber-Defence-Platform/docs/attack_matrix.md")
    matrix_md_path.parent.mkdir(parents=True, exist_ok=True)
    with open(matrix_md_path, 'w') as f:
        f.write("# MITRE ATT&CK Coverage Matrix\n\n")
        f.write("| Tactic / Technique | Detection Rules |\n")
        f.write("|-------------------|-----------------|\n")
        for tactic, rule_titles in matrix.items():
            f.write(f"| **{tactic}** | {', '.join(rule_titles)} |\n")
    print(f"\nATT&CK Matrix written to {matrix_md_path}")

if __name__ == "__main__":
    main()
