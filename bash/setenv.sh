#!/bin/bash
source ./setenv-func.sh

setenv "TESTENV1" "TESTENV2"
set +H
setSecret "TESTENV_SECRET"
set -H
env | grep "TESTENV"