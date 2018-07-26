#!/usr/bin/env bats

load test_helper
fixtures bats


@test "taccreg help text displays" {
  run taccreg -h
  [ $status -eq 0 ]
  [ $(expr "${lines[2]}" : "taccreg") -ne 0 ]
}
