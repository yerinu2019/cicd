#!/bin/bash
if [ ! -d "$HOME/bin" ]; then
  mkdir $HOME/bin
  export PATH=$HOME/bin:$PATH
fi

echo "Install opa"
curl -L -o $HOME/bin/opa https://github.com/open-policy-agent/opa/releases/download/v0.34.2/opa_linux_amd64
chmod 755 $HOME/bin/opa

echo "Install tekton cli"
sudo apt update;sudo apt install -y gnupg
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 3EFE0E0A2F2F60AA
echo "deb http://ppa.launchpad.net/tektoncd/cli/ubuntu eoan main"|sudo tee /etc/apt/sources.list.d/tektoncd-ubuntu-cli.list
sudo apt update && sudo apt install -y tektoncd-cli
