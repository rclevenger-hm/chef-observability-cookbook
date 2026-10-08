# Testing and coverage boundaries

## Automated jobs

| Job | What it proves |
| --- | --- |
| Unit | Pure Ruby input validation, TLS template rendering, atomic metrics writes, ChefSpec resource wiring, configuration profiles on Ubuntu and Rocky fixtures |
| Converge | Actual Chef application on Ubuntu, real exporter service and HTTP metrics, commercial configuration using fixture accounts, second converge with zero changes, protected file modes |
| Demo | Docker build runs Chef twice, Prometheus parses configuration/rules, real scrape target is healthy, Grafana serves the provisioned dashboard |

Datadog and Splunk delivery is not tested against commercial services. Those resource
configurations are converged with fixture users and service management disabled.
Rocky platform simulation is not equivalent to a real Rocky VM converge. ARM64 archive
selection is tested; runtime CI uses AMD64. The optional Kitchen suite covers full VM
behavior when run by a maintainer with the required environment.

## Commands

Use Ruby 3.3 for development, CI, releases, and the Docker demo. The `Gemfile`
declares the supported Ruby series so dependency updates resolve compatible gems.
Minitest 6 requires Ruby 3.2 or later; the previous Ruby 3.1 runner cannot install it.
The maintained `gitlab-ruby-shadow` fork provides Chef's `shadow` extension on newer Ruby;
the original `ruby-shadow` 2.5.1 cannot compile there.

```sh
bundle install
bundle exec rake
bundle exec cookstyle --only Chef/Correctness,Lint
GRAFANA_ADMIN_PASSWORD="$(openssl rand -hex 24)" docker compose -f demo/compose.yaml up --build -d
python3 scripts/check_demo.py
```

The Ruby gem distribution is invoked through `scripts/chef_client.rb`, which loads
Chef's application entrypoint. Chef Workstation installations may use `chef-client`
directly. `test/client.rb` is exclusively a disposable integration test configuration.

The automated converge and demo use Chef 18. Chef 19 from RubyGems requires a runtime
license key, so its major update is intentionally excluded from Dependabot until a
licensed test environment is available. Chef 18 minor and patch updates remain enabled.
See [Chef 19 licensing](https://docs.chef.io/client/19/license/) for the requirements.

For the optional VM suite, install Chef Workstation, Vagrant, a compatible hypervisor,
and the `kitchen-vagrant`/`kitchen-inspec` plugins. Review Chef's license configuration
for your environment before running `kitchen test`. The suite converges twice and
enforces idempotence, then runs the InSpec controls.

## Negative cases

Tests reject incomplete or non-HTTPS artifacts, unknown architectures, mismatched
collector settings, invalid ports, injected configuration stanzas, duplicate log monitors,
missing secrets, and incomplete TLS identities. These are intended regressions gates,
not substitutes for validating actual vendor delivery in staging.
