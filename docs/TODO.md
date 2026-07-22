# Project TODO

## Bifrost modernization

- [ ] Migrate to the Bifrost revision used by a newer upstream kallisto release.
  Do this as a separate compatibility project rather than a routine dependency
  update: preserve kallisto's required graph and binary-index APIs, retain MSVC
  support, and verify index round trips plus quantification results on
  representative datasets before adopting the new revision.

