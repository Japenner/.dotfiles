#!/usr/bin/env bash

edit_gem() {
  $CODE_EDITOR "$(bundle show "$1")"
}
