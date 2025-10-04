#!/usr/bin/env python3
"""Fail unless a real exporter is scraped and the provisioned dashboard exists."""
import json
import time
from urllib.request import urlopen


def get(url):
    with urlopen(url, timeout=5) as response:
        return json.load(response)


def main():
    deadline = time.monotonic() + 120
    last_error = None
    while time.monotonic() < deadline:
        try:
            result = get('http://127.0.0.1:9090/api/v1/query?query=node_uname_info')
            assert result['status'] == 'success' and result['data']['result'], 'No exported host metrics'
            targets = get('http://127.0.0.1:9090/api/v1/targets')['data']['activeTargets']
            assert any(t['labels']['job'] == 'node' and t['health'] == 'up' for t in targets), 'Exporter is down'
            dashboard = get('http://127.0.0.1:3000/api/dashboards/uid/chef-host-overview')
            assert len(dashboard['dashboard']['panels']) == 6, 'Dashboard is incomplete'
            print('PASS: real host metrics, healthy scrape target, six provisioned dashboard panels')
            return
        except Exception as error:
            last_error = error
            time.sleep(3)
    raise SystemExit(f'Demo failed: {last_error}')


if __name__ == '__main__':
    main()
