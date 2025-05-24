# Splunk Universal Forwarder

This resource manages a dedicated app at
`/opt/splunkforwarder/etc/apps/chef_observability/local/` and a `SplunkForwarder` unit.
Use it for a standalone Linux UF whose installation tree belongs to `splunk:splunk`.
An existing installation with another service account or unit owner must be reconciled
before enabling service management. Do not run two systemd units for the same forwarder.

```ruby
observability_splunk_forwarder 'application-logs' do
  servers ['indexer-a.example.net:9997', 'indexer-b.example.net:9997']
  server_names ['indexer-a.example.net', 'indexer-b.example.net']
  ca_file '/opt/splunkforwarder/etc/auth/receiver-ca.pem'
  monitors [{ 'path' => '/var/log/payments/*.log', 'index' => 'payments', 'sourcetype' => 'payments:json' }]
end
```

The receiver CA must already be installed and readable by the service account.
Receiver DNS names must match certificate identities. The target must support Splunk's
TLS forwarding protocol. This is **not** an HTTP Event Collector integration.

The app sets `useSSL`, `sslVerifyServerCert`, and `sslVerifyServerName` to true, configures
acknowledgments and receiver rotation, and places its CA setting in `server.conf`.
This initial version supports server-authenticated TLS. Receiver setups requiring client
certificates and Splunk Cloud credentials apps need additional, separately managed configuration.

## Fresh installation

Provide a native `package_version` and either an approved repository or verified artifact.
The operator must explicitly set `accept_license true` after reviewing the vendor terms.
Provide a first-start password through `node.run_state['observability']['splunk_admin_password']`
when using the recipe, or the sensitive `admin_password` resource property.
The seed file is mode `0600` and is only written before `etc/passwd` exists.
Splunk consumes the seed during its initial startup.

Do not assume package installation grants the service user access to application logs.
Use narrowly scoped groups or ACLs. Existing Deployment Server configurations may override
app settings; inspect merged configuration before rollout:

```sh
sudo -u splunk /opt/splunkforwarder/bin/splunk btool outputs list --debug
sudo -u splunk /opt/splunkforwarder/bin/splunk btool inputs list --debug
sudo journalctl -u SplunkForwarder --since '10 minutes ago'
```

CI renders and converges the app with fixture accounts and service management disabled.
No licensed Splunk process or remote indexer is used in CI. Verify certificate trust,
agent startup, acknowledgments, and an actual ingested event in a staging environment.

Reference: https://help.splunk.com/en/splunk-enterprise/administer/admin-manual/10.0/configuration-file-reference/10.0.0-configuration-file-reference/outputs.conf
