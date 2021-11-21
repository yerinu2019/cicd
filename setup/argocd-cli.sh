#!/bin/bash
echo "Install argocd cli"
curl -sSL -o $HOME/bin/argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64 && chmod +x $HOME/bin/argocd