# Report rejected native saved-match writes

Baseline: main `1bc591318b4801949c2f616e8ce13549bf0ee012`.

Confirmed reliability defect: SharedPreferences.setString returns a boolean, but
SavedMatchStore.save ignored false. MatchPersistenceController consequently set
lastSaveSucceeded=true and the existing exit flow could promise saved recovery
even though native storage rejected the write.

The regression uses the real preferences method channel with a false native
result, not an injected exception. Before the fix it fails: expected false,
actual true. After the three-line store correction it verifies failure reporting,
absence from durable storage after cache reload, successful later write, and
successful read after another cache reload. The existing queue/error handling
and exit dialog now receive the correct outcome. No UI, rule, snapshot schema,
mode gate, board asset, geometry or MatchSession change.

Local validation:189-file strict format PASS; fatal-info analyzer PASS; focused
five tests PASS; full447-test unit/widget/domain suite PASS. These are not
physical-device/process-death guarantees. Fresh Android/iOS build/installed CI
results belong to this PR's exact revision and must not be inferred from main's
or another PR's historical run. No automatic merge or release gate clearance.
