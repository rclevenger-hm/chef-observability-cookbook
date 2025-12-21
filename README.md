# Chef Observability Cookbook

[![Cookbook CI](https://github.com/rclevenger-hm/chef-observability-cookbook/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/rclevenger-hm/chef-observability-cookbook/actions/workflows/ci.yml)

Manage Linux host telemetry with Chef: Prometheus Node Exporter, Grafana dashboards,
Datadog Agent configuration, and Splunk Universal Forwarder configuration.

The cookbook name is **`observability`**. It has no third-party cookbook dependencies.
It is intended for infrastructure teams that want small, reviewable resources,
explicit package versions, protected credentials, and repeatable changes.

## What is included

| Component | Behavior |
| --- | --- |
| Node Exporter | Verified release archive, AMD64/ARM64 selection, unprivileged systemd service, collector selection, loopback binding by default |
| Datadog | Runtime API-key injection, restrictive file permissions, host tags, opt-in file logs, pinned package installation when requested |
| Splunk UF | Managed app, file monitors, receiver load balancing, acknowledgments, mandatory TLS and hostname verification |
| Prometheus | Deterministic file discovery targets and example alerts |
| Grafana | Provisioned host dashboard with CPU, memory, filesystem, network, and Chef health panels |
| Chef health | Atomic textfile metrics for successful and failed runs; no node attributes or exception messages exported |

Datadog and Splunk are disabled by default. Their agents need your vendor packages,
accounts, endpoints, and credentials. The demo uses Prometheus and Grafana only.

## Run the demo

Requires Docker Engine with Docker Compose v2. From the repository root:

```sh
export GRAFANA_ADMIN_PASSWORD="$(openssl rand -hex 24)"
docker compose -f demo/compose.yaml up --build -d
python3 scripts/check_demo.py
```

Open [Grafana](http://localhost:3000/d/chef-host-overview) or
[Prometheus](http://localhost:9090). Grafana is a local, anonymous **Viewer** demo;
login is disabled. Ports bind to loopback. Do not expose this Compose stack publicly.

The exporter image actually runs Chef twice during its build and requires the second
run to update zero resources. It then starts the binary installed by the cookbook.
Metrics describe the container's view of the system, not a complete production host.
Chef health panels remain empty until `observability::chef_metrics` runs on a monitored host.

```sh
docker compose -f demo/compose.yaml down        # retain demo data
docker compose -f demo/compose.yaml down -v     # also delete demo data
```

## Use with Chef

Target: Chef Infra Client 18+, Ubuntu 22.04/24.04 and Rocky Linux 9 with systemd.
See [testing](docs/testing.md) for what is exercised in CI versus fixture-only coverage.

```ruby
# Policyfile.rb in your infrastructure repository
name 'host-monitoring'
default_source :supermarket
run_list 'observability::default', 'observability::chef_metrics'
cookbook 'observability', git: 'https://github.com/rclevenger-hm/chef-observability-cookbook',
                         ref: '<reviewed-commit-sha>'
```

Install/export the Policyfile with Chef Workstation before deployment. Alternatively,
put this repository in your cookbook path under the name `observability`.

```ruby
observability_node_exporter 'host' do
  listen_address '127.0.0.1:9100'
  collectors %w(systemd)
end
```

For remote Prometheus scraping, choose a private bind address and restrict access to
the scraper through your firewall. This resource does not open firewall ports.

## Documentation

- [Resource reference](docs/resources.md) and [configuration profiles](docs/configuration.md)
- [Datadog integration](docs/datadog.md) and [Splunk forwarding](docs/splunk.md)
- [Architecture](docs/architecture.md), [security](SECURITY.md), and [operations](docs/operations.md)
- [Local demo](demo/README.md), [testing](docs/testing.md), and [release process](docs/releases.md)
- [Development roadmap](docs/roadmap.md) and [history notes](HISTORY.md)

## Development

```sh
bundle install
bundle exec rake
bundle exec cookstyle --only Chef/Correctness,Lint
```

See [CONTRIBUTING.md](CONTRIBUTING.md) for test expectations. Apache-2.0 licensed.
