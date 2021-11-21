#!/bin/bash
if [ ! -d "$HOME/bin" ]; then
  mkdir $HOME/bin
  export PATH=$HOME/bin:$PATH
fi

echo "Install opa"
curl -L -o $HOME/bin/opa https://github.com/open-policy-agent/opa/releases/download/v0.11.0/opa_linux_amd64
chmod 755 $HOME/bin/opa

