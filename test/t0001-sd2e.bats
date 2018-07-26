#!/usr/bin/env bats

load test_helper
fixtures bats


@test "sd2e is executable" {
  run sd2e
  [ $status -eq 0 ]
  [ $(expr "${lines[0]}" : "These") -ne 0 ]
}

@test "sd2e info help text displays properly" {
  run sd2e info -h
  [ $status -eq 0 ]
  [ $(expr "${lines[0]}" : "Information") -ne 0 ]
}

@test "sd2e info displays properly" {
  run sd2e info
  [ $status -eq 0 ]
  [ $(expr "${lines[0]}" : "DARPA") -ne 0 ]
}

@test "sd2e status check help text displays" {
  run sd2e status -h
  [ $status -eq 0 ]
  [ $(expr "${lines[0]}" : "usage") -ne 0 ]
}

@test "sd2e upgrade help text displays" {
  run sd2e upgrade -h
  [ $status -eq 0 ]
  [ $(expr "${lines[0]}" : "upgrade") -ne 0 ]
}

@test "sd2e commands helper works" {
  run sd2e commands
  [ $status -eq 0 ]
  [ $(expr "${lines[0]}" : "Usage") -ne 0 ]
}
