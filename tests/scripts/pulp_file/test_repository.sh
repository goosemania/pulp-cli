#!/bin/sh

# shellcheck source=tests/scripts/config.source
. "$(dirname "$(dirname "$(realpath "$0")")")"/config.source

pulp debug has-plugin --name "file" || exit 3

cleanup() {
  pulp file repository destroy --name "cli_test_file_repo" || true
  pulp file remote destroy --name "cli_test_file_remote1" || true
  pulp file remote destroy --name "cli_test_file_remote2" || true
}
trap cleanup EXIT

REMOTE1_HREF="$(pulp file remote create --name "cli_test_file_remote1" --url "http://a/" | jq -r '.pulp_href')"
REMOTE2_HREF="$(pulp file remote create --name "cli_test_file_remote2" --url "http://b/" | jq -r '.pulp_href')"

expect_succ pulp file repository list

expect_succ pulp file repository create --name "cli_test_file_repo" --description "Test repository for CLI tests"
expect_succ pulp file repository update --name "cli_test_file_repo" --description "" --remote "cli_test_file_remote1"
expect_succ pulp file repository show --name "cli_test_file_repo"
expect_succ test "$(echo "$OUTPUT" | jq -r '.remote')" = "$REMOTE1_HREF"
expect_succ pulp file repository update --name "cli_test_file_repo" --remote "cli_test_file_remote2"
expect_succ pulp file repository show --name "cli_test_file_repo"
expect_succ test "$(echo "$OUTPUT" | jq -r '.remote')" = "$REMOTE2_HREF"
expect_succ pulp file repository update --name "cli_test_file_repo" --remote ""
expect_succ pulp file repository show --name "cli_test_file_repo"
expect_succ test "$(echo "$OUTPUT" | jq -r '.description')" = "null"
expect_succ test "$(echo "$OUTPUT" | jq -r '.remote')" = ""
expect_succ pulp file repository list
test "$(echo "$OUTPUT" | jq -r '.|length')" != "0"

expect_succ pulp file repository task list --repository "cli_test_file_repo"
test "$(echo "$OUTPUT" | jq -r '.|length')" = "3"

if pulp debug has-plugin --name "core" --min-version "3.10.dev"
then
  expect_succ pulp repository list
  test "$(echo "$OUTPUT" | jq -r '.|length')" != "0"
  expect_succ pulp repository list --name "cli_test_file_repo"
  test "$(echo "$OUTPUT" | jq -r '.|length')" = "1"
  expect_succ pulp repository list --name-contains "cli_test_file"
  test "$(echo "$OUTPUT" | jq -r '.|length')" = "1"
  expect_succ pulp repository list --name-icontains "CLI_test_file"
  test "$(echo "$OUTPUT" | jq -r '.|length')" = "1"
  expect_succ pulp repository list --name-in "cli_test_file_repo"
  test "$(echo "$OUTPUT" | jq -r '.|length')" = "1"
fi
expect_succ pulp file repository destroy --name "cli_test_file_repo"
