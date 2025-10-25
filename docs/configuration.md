# Configuration profiles

`observability::default` selects integrations using `node['observability']`.
The defaults enable Node Exporter and leave commercial integrations disabled.

```json
{
  "observability": {
    "node_exporter": { "enabled": true, "listen_address": "10.20.1.10:9100" },
    "datadog": { "enabled": false },
    "splunk": { "enabled": false }
  }
}
```

Set attributes in your wrapper cookbook or Policyfile; keep secrets in `node.run_state`.
Calling an integration recipe directly enables that integration regardless of its
`enabled` selector. Setting `enabled: false` stops managing it; it does **not** uninstall
the package or stop an existing service. See the removal runbook.

## Package ownership

Configure an organization's approved vendor repository before setting `manage_package`.
Use exact DEB/RPM version strings, including epoch/release suffixes where applicable.
Alternatively provide an HTTPS artifact URL and SHA-256 digest in the wrapper cookbook.
Credentials embedded in URLs are rejected. Authenticated artifact delivery should be
handled by a separate provisioning layer that exposes an appropriate approved URL.

## Avoid two managers

Do not concurrently manage Datadog's root configuration through another cookbook.
Do not deploy a conflicting `chef_observability` Splunk app through Deployment Server.
Chef owns files documented by each resource; it leaves other integration directories intact.
