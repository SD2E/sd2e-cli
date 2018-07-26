#!/usr/bin/env bats

load test_helper
fixtures bats


@test "tacclab help text displays" {
  run tacclab -h
  [ $status -eq 0 ]
  [ $(expr "${lines[4]}" : "Usage") -ne 0 ]
}
