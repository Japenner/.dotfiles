#!/usr/bin/env bash

# Make directory and change into it
function mcd() {
  mkdir -p "$1" && cd "$1"
}

# Function to go up multiple directories based on the number of dots used
up() {
  local count=${#1}
  local path=$(printf '../%.0s' $(seq 1 $count))
  cd "$path" || return 1
}
