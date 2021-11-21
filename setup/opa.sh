#!/bin/bash
echo "Install opa"
curl -L -o $HOME/bin/opa https://github.com/open-policy-agent/opa/releases/download/v0.34.2/opa_linux_amd64
chmod 755 $HOME/bin/opa