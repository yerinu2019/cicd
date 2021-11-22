#!/bin/bash
export ISTIOCTL_VERSION=1.11.2
curl -L https://istio.io/downloadIstio | ISTIO_VERSION=${ISTIOCTL_VERSION} sh -
CHECK=`env | grep PATH | grep "istio-${ISTIOCTL_VERSION}/bin"`
if [[ -z "${CHECK}" ]]; then
  export PATH=istio-${ISTIOCTL_VERSION}/bin:$PATH
fi

