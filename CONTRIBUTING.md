# Contributing

Open a focused issue or pull request with the operational problem, proposed behavior,
and a reproducible example. Avoid introducing credentials or environment-specific inventories.

Use Ruby 3.3 (`.ruby-version`), then run `bundle install`, `bundle exec rake`,
and `bundle exec cookstyle --only Chef/Correctness,Lint`.
For resource changes, exercise a fresh converge and a second no-change converge.
For dashboard or scrape changes, run the Docker demo and `python3 scripts/check_demo.py`.

Add a regression test that fails for the bug being fixed. Prefer tests of emitted
configuration, permissions, service behavior or failed inputs over tests of internal method names.
Platform support claims should distinguish catalog simulation from a real converge.

Keep package versions explicit. Adding a Node Exporter version requires independently
verifying the upstream checksums for each supported architecture. Update documentation
and the release notes whenever resource behavior changes.
