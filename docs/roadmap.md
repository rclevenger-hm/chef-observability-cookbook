# Roadmap

## Available in 0.1

- Optional Datadog and Splunk integrations with explicit configuration ownership.
- Verified Node Exporter installation, unprivileged systemd service and collector selection.
- Prometheus discovery, example alerts and a Grafana host dashboard.
- Chef run textfile metrics, configuration tests and executable CI/demo checks.
- Scoped package build and release validation.

## Next milestones

1. Run a complete Rocky Linux VM and ARM64 matrix in hosted CI.
2. Add a staged Datadog/Splunk delivery test with dedicated sandbox credentials.
3. Support Splunk client certificates and configurable service-account migration.
4. Add exporter-toolkit web TLS/auth configuration for remote scraping.
5. Support explicit agent removal with buffer-retention safeguards.
6. Add backend-specific configuration preflight against a staged directory before activation.

OpenTelemetry is outside the initial scope. Future integrations should have a concrete
operational use case, tested rollout behavior and clear ownership of the files they manage.
