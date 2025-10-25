# Resource reference

## observability_node_exporter

Action: `:install`. Installs the versioned archive below `/opt/node_exporter`, links the
binary into `/usr/local/bin`, and creates `node_exporter.service`.

| Property | Default | Notes |
| --- | --- | --- |
| `version` | `1.10.2` | Stable semantic version |
| `checksum` | Built-in AMD64/ARM64 digest for 1.10.2 | Required for other versions |
| `download_base` | GitHub releases | HTTPS mirror allowed; same release path layout |
| `listen_address` | `127.0.0.1:9100` | IPv6 uses `[address]:port` |
| `collectors` | `[]` | Additional collectors |
| `disabled_collectors` | `[]` | Disable default collectors |
| `textfile_directory` | `/var/lib/node_exporter/textfile_collector` | Root-owned; producers must write valid metrics atomically |
| `manage_service` | `true` | Set false only when another process supervisor owns startup |

Conflicting collectors, invalid ports, unsupported architectures and missing checksums
fail before downloading. Previous version directories remain available for rollback.
Archive checksums verify downloads; this is not a continuous binary integrity monitor.

## observability_agent_package

Action: `:install`. Requires package name and exact native package `version`.
Without `source_url`, uses an already configured, trusted package repository.
With `source_url`, requires HTTPS and a SHA-256 `checksum`, then installs the downloaded
DEB or RPM. Debian dependencies must already be available when using `dpkg_package`.
It does not configure vendor repositories or automatically accept licenses.

## observability_datadog_agent

Action: `:configure`. Requires `api_key`; other properties are `site`, `tags`, `logs`,
`manage_package`, `package_version`, `package_url`, `package_checksum`, and `manage_service`.
Package and service details are in [datadog.md](datadog.md).

## observability_splunk_forwarder

Action: `:configure`. Requires `servers`, `server_names`, and `ca_file`.
Accepts `monitors`, `home`, package properties, `accept_license`, `admin_password`,
and `manage_service`. Review [splunk.md](splunk.md) before taking ownership of an existing forwarder.

## observability_prometheus_scrape

Action: `:create`. Requires `targets` (host:port array). Optional `labels` has string keys
and values; reserved `__` labels are rejected. Writes stable JSON to `path`, default
`/etc/prometheus/file_sd/chef_hosts.json`. `owner` and `group` default to root.
Prometheus automatically refreshes file discovery without a service restart.
An empty target list intentionally removes this resource's discovered hosts.

## observability_grafana_dashboard

Action: `:create`. Installs the included dashboard into `directory`, default
`/var/lib/grafana/dashboards`. Owner/group default to `grafana` and must already exist.
Configure a file dashboard provider and a Prometheus datasource with UID `prometheus`;
working examples are in `demo/grafana/provisioning/`.
