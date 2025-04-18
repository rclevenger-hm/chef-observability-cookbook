# Datadog Agent

The resource manages an existing Agent 7 installation by default. The `dd-agent` user
and group must exist. To install, provide `manage_package true` and an exact package
version from your approved repository, or supply a verified package artifact.

```ruby
# A wrapper cookbook resolves this from your secret store at run time.
api_key = node.run_state.fetch('observability').fetch('datadog_api_key')
observability_datadog_agent 'host' do
  api_key api_key
  site 'datadoghq.com'
  tags ['env:production', 'team:platform', 'service:payments']
  logs [{ 'path' => '/var/log/payments/*.log', 'service' => 'payments', 'source' => 'ruby' }]
  sensitive true
end
```

The recipe also accepts `OBSERVABILITY_DATADOG_API_KEY` for ephemeral environments.
Run-state injection is preferred on Chef Server-managed hosts. Never put keys in node
attributes, Policyfiles, JSON profiles, logs, or Git. The application key is not needed.

`/etc/datadog-agent/datadog.yaml` is rendered as JSON, which is valid YAML, to safely
escape values. It is owned by `dd-agent` with mode `0600`; Chef suppresses its diff.
Log configuration is isolated under `conf.d/observability.d/conf.yaml`.
Removing a log from the resource removes it from that managed configuration.

APM and process collection default to disabled. The resource is intentionally focused
on host metrics and explicit log sources. Grant `dd-agent` read access only to selected
application logs using your application's ownership/ACL policy. Do not make all logs world-readable.

Validate after rollout:

```sh
sudo datadog-agent configcheck
sudo datadog-agent status
sudo journalctl -u datadog-agent --since '10 minutes ago'
```

CI verifies configuration generation and file protection using fixture users. It does
not claim successful delivery to a Datadog account. Complete that check in your environment.

Reference: https://docs.datadoghq.com/agent/supported_platforms/chef/
