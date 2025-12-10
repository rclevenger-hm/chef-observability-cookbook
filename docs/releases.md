# Release process

1. Run the complete CI workflow for the candidate commit.
2. Verify backend delivery in staging for any changed commercial agent integration.
3. Update `metadata.rb`, `CHANGELOG.md` and the compatibility notes.
4. Build with `bundle exec ruby scripts/package.rb` and inspect the resulting archive.
5. Tag the reviewed commit as `v<metadata version>` and push the tag.

The tag workflow repeats validation and uploads an `observability-<version>.tar.gz`
Actions artifact. It checks the tag against the cookbook version before packaging.
It does not publish to Chef Supermarket or deploy a fleet. Download the artifact for
your normal reviewed distribution process.

The package includes only cookbook runtime directories, metadata, README and license.
CI fixtures, credentials, vendored gems and local caches are excluded by the packager.
Pin consumers to the tested commit or version and retain the previous version for rollback.
