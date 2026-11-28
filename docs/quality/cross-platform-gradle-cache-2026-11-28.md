# Cross-platform Android dependency fetch failure

Run46091190276, job140812214751 failed before app compilation. Gradle could not
resolve Kotlin2.0.21 stdlib/plugin/BOM: repo.maven.apache.org returned HTTP429.
This establishes dependency retrieval failure, not an application/rendering defect.
The actual failed log was inspected before any retry/configuration change.

The cross-platform Android job had no Gradle cache, unlike foundation, recording
and checkpoint jobs. Reuse the same pinned cache6 action, paths and lockfile/wrapper
key in that job after runner generation. Existing validated cached dependencies
can be restored instead of unnecessarily fetching the entire graph cold. Missing
or rejected artifacts still fail the real build; no timeout, repository, checksum,
required screenshot, test or failure gate is relaxed. A cache is mitigation for
cold-fetch pressure, not a guarantee that Maven never returns429.

This change stacks on PR99's current-main reconciliation. It changes one workflow
and this diagnosis only. Source, assets, identifiers, gameplay and native scripts
are unchanged. Require fresh exact-head cache/build/platform checks before merge.

Evidence distinction: cross-platform Android builds a normal debug APK. Installed
Android acceptance comes from the separate emulator checkpoint/recording workflow;
an APK build alone must not be described as an installed-app test. The macOS job
builds iOS and runs installed simulator navigation. Physical acceptance is separate.
