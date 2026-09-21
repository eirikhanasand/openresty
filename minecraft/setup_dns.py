#!/usr/bin/env python3
"""Create explicit Inspur addresses and Minecraft SRV records. Dry-run unless --apply."""
import argparse, base64, configparser, json, urllib.request
from pathlib import Path

NAMES = ('name-pending', '67', 'cobbleverse')
DOMAIN = 'hanasand.com'

def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--apply', action='store_true')
    p.add_argument('--credentials', type=Path, default=Path('/home/hanasand/openresty/letsencrypt/domeneshop.ini'))
    args = p.parse_args()
    config = configparser.ConfigParser()
    config.read_string('[auth]\n' + args.credentials.read_text())
    auth = config['auth']
    token = auth['dns_domeneshop_client_token'] + ':' + auth['dns_domeneshop_client_secret']
    header = 'Basic ' + base64.b64encode(token.encode()).decode()
    def api(path, method='GET', body=None):
        req = urllib.request.Request('https://api.domeneshop.no/v0/' + path, method=method,
            data=None if body is None else json.dumps(body).encode(),
            headers={'Authorization': header, 'Content-Type': 'application/json'})
        with urllib.request.urlopen(req, timeout=30) as r:
            content = r.read()
            return json.loads(content) if content else None
    domain = next(d for d in api('domains?domain=' + DOMAIN) if d['domain'] == DOMAIN)
    path = f'domains/{domain["id"]}/dns'
    records = api(path)
    desired = []
    for name in NAMES:
        desired += [dict(host=name, type='A', data='128.39.142.218', ttl=300),
                    dict(host='_minecraft._tcp.' + name, type='SRV', data=name + '.' + DOMAIN + '.',
                         priority=0, weight=0, port=443, ttl=300)]
    for record in desired:
        matches = [r for r in records if r['host'] == record['host'] and r['type'] == record['type']]
        if len(matches) > 1:
            raise RuntimeError('Multiple existing records require review: ' + record['host'])
        if matches and all(str(matches[0].get(k)) == str(v) for k,v in record.items()):
            print('Unchanged:', record['host'], record['type'])
            continue
        print('Update' if matches else 'Create', json.dumps(record))
        if args.apply:
            api(path + '/' + str(matches[0]['id']), 'PUT', record) if matches else api(path, 'POST', record)
    if args.apply:
        saved = api(path)
        for r in desired:
            assert any(all(str(x.get(k)) == str(v) for k,v in r.items()) for x in saved), r
        print('Verified all six DNS records.')

if __name__ == '__main__':
    main()
