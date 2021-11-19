#!/bin/bash

function setenv() {
  for envName in "$@"
  do
    echo -n "set environment variable value ${envName}: "
    read input
    if [[ -z "${input}" ]]; then
      echo "environtment variable ${envName} is not set"
      exit 1
    fi
    export ${envName}="$input"
    #if [[ -z "${!envName}" ]]; then
    #fi
  done
}

function setSecret() {
  for envName in "$@"
    do
      echo -n "Enter ${envName} value: "
      read -s input
      echo
      if [[ -z "${input}" ]]; then
        echo "environtment variable ${envName} is not set"
        exit 1
      fi
      export ${envName}="$input"
      #if [[ -z "${!envName}" ]]; then
      #fi
    done
}

