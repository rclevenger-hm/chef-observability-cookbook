# Security

Report vulnerabilities privately through the repository owner's GitHub contact options.
Do not publish credentials, customer logs, host inventories or exploitable infrastructure details.

- Node Exporter binds to loopback and runs without root or ambient capabilities.
- Binary artifacts require HTTPS and verified SHA-256 digests.
- Agent package versions are explicit; vendor repository configuration stays under operator control.
- Datadog keys and Splunk seed passwords are sensitive resource properties and are not node attributes.
- Splunk forwarding requires TLS certificate and hostname verification. There is no insecure-mode toggle.
- The demo uses loopback ports and anonymous read-only Grafana access; it is not a public deployment template.

Package and container pins are reviewable baselines, not a promise of ongoing vendor
support or absence of vulnerabilities. Review vendor advisories and update pins with
the validation suite before production deployment. Checksum verification authenticates
artifact bytes against the configured digest; it does not establish that a release is vulnerability-free.

Host log access, firewall rules, backend authorization, secret retrieval, data retention,
and redaction remain deployment responsibilities. The cookbook is not a compliance certification.
