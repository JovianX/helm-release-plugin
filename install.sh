#!/usr/bin/env bash
set -o errexit
set -o nounset
set -o pipefail

command -v curl >/dev/null 2>&1 || { echo >&2 "curl is required but it's not installed. Aborting."; exit 1; }
command -v jq >/dev/null 2>&1 || { echo >&2 "jq is required but it's not installed. Aborting."; exit 1; }
command -v uname >/dev/null 2>&1 || { echo >&2 "uname is required but it's not installed. Aborting."; exit 1; }

VERSION=$(curl --silent "https://api.github.com/repos/mikefarah/yq/releases/latest" | jq -r .tag_name)

OS="$(uname | tr '[:upper:]' '[:lower:]')"

case $OS in
    darwin*)  BINARY="yq_darwin_amd64" ;;
    linux*)   BINARY="yq_linux_amd64" ;;
    *)        printf '%s\n' "Unsupported operating system($OS) detected while installing yq." >&2;exit 1 ;;
esac

curl --silent -L https://github.com/mikefarah/yq/releases/download/${VERSION}/${BINARY} -o ${HELM_PLUGIN_DIR}/lib/yq;

chmod +x ${HELM_PLUGIN_DIR}/lib/yq;
