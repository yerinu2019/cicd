#!/bin/bash
if [ ! -d "$HOME/bin" ]; then
  mkdir $HOME/bin
  export PATH=$HOME/bin:$PATH
fi

