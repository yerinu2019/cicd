FROM flant/shell-operator:latest
RUN apk --no-cache add curl
RUN cd /bin && curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh"  | bash
ADD hooks /hooks