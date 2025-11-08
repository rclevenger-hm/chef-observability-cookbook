# Operations runbook

## Rollout

1. Review the exact cookbook commit, package versions, artifact digests and destination addresses.
2. Converge one disposable host. Validate the selected agent's configuration and backend arrival.
3. Converge again and investigate unexpected changes or restarts.
4. Deploy to one canary from each OS/architecture group, then a small batch.
5. Watch scrape health, log volume, CPU/memory overhead and backend ingestion costs before expanding.

## Node Exporter unavailable

Check `systemctl status node_exporter` and `journalctl -u node_exporter`.
Query `http://127.0.0.1:9100/metrics` locally. If that works, check bind address,
firewall policy and the Prometheus target. Loopback is intentionally the default.
Some opt-in collectors need extra host access and may conflict with unit hardening;
test their metric families before rolling them out.

## Roll back an exporter upgrade

Revert both `version` and `checksum` to the previously tested pair and converge.
The versioned directory is retained. Chef updates the symlink and restarts the service.
Do not change only a digest to work around a download failure.

## Configuration rejected

Check destination syntax, mandatory TLS names, duplicate monitor paths and exact package
versions. For Datadog, verify that the secret provider populated run_state. Never paste
keys into an issue or disable sensitive output to debug authentication.

## Chef metrics are stale

Ensure `observability::chef_metrics` is on the run list, Chef runs on a schedule, the
textfile directory matches the exporter flag, and the file is readable by `node_exporter`.
The handler records unsuccessful runs after it has been enabled. Failures before handler
registration are detected by the stale timestamp alert, not a fresh failure metric.

## Remove an integration

An `enabled: false` selector only stops management. In a reviewed maintenance change:
stop/disable the service, remove this cookbook's managed files, and uninstall the package
if no other workload needs it. Remove its discovery target and backend integration.
Retain buffers or checkpoints until log delivery requirements are satisfied.
This cookbook never automatically deletes Splunk's queue or checkpoint directories.
