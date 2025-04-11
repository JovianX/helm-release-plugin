#!/usr/bin/env bash
set -o errexit
set -o nounset
set -o pipefail

for cmd in curl jq uname tr chmod printf; do
  if ! command -v $cmd &> /dev/null; then
    echo "$cmd could not be found. Please install it."
    exit 1
  fi
done

VERSION=$(curl --silent "https://api.github.com/repos/mikefarah/yq/releases/latest" | jq -r .tag_name)

OS="$(uname | tr '[:upper:]' '[:lower:]')"

case $OS in
    darwin*)  BINARY="yq_darwin_amd64" ;;
    linux*)   BINARY="yq_linux_amd64" ;;
    *)        printf '%s\n' "Unsupported operating system($OS) detected while installing yq." >&2;exit 1 ;;
esac

curl --silent -L https://github.com/mikefarah/yq/releases/download/${VERSION}/${BINARY} -o ${HELM_PLUGIN_DIR}/lib/yq;

chmod +x ${HELM_PLUGIN_DIR}/lib/yq;
