#!/usr/bin/env bash
# Regenerates docs/user_guides/screenshots/ from the real app.
#
# Each journey runs in its own `flutter test` process: Hive is opened once per
# process and its write queue belongs to the first test that used it, so a
# second login in the same process never finishes saving.
#
#   bash docs/user_guides/make_screenshots.sh
set -e
cd "$(dirname "$0")/../.."
rm -rf docs/user_guides/screenshots/{common,signup,office,client,staff,rm}
for journey in common signup "office login" client staff rm; do
  echo "── $journey"
  flutter test test/user_flow_walkthrough_test.dart \
    --plain-name "$journey" \
    --dart-define=USE_DUMMY_API=true \
    --dart-define=ENABLE_OFFLINE_CACHE=false \
    | grep -E '^FLOW\|(MISS|API\|404)|All tests passed|Some tests failed' \
    | grep -v -E '/app/version|/meta/series' || true
done
