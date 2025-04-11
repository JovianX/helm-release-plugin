#!/usr/bin/env bash
function pull_chart_from_release() {

	local msg="usage: helm release pull <RELEASE NAME> [-d | --destination <TARGET CHART DIRECTORY>] [-o | --output [yaml | json | text]]"
	NAMESPACE=$HELM_NAMESPACE
	K8S_CONTEXT=$HELM_KUBECONTEXT
	DESTINATION_DIR="."
	RELEASE=""
	OUTPUT="text"

	while test $# -gt 0; do
		case "$1" in
			(-d|--destination)
				shift
				if test $# -gt 0; then
					export DESTINATION_DIR=$1
				else
					exit_with_help "$msg"
				fi
				shift
				;;
			--destination*)
				export DESTINATION_DIR=`echo $1 | sed -e 's/^[^=]*=//g'`
				shift
				;;
			(-o|--output)
				shift
				if test $# -gt 0; then
					export OUTPUT=$1
					if [ "$OUTPUT" != "text" ] && [ "$OUTPUT" != "yaml" ] && [ "$OUTPUT" != "json" ]; then
						exit_with_help "$msg"
					fi
				else
					exit_with_help "$msg"
				fi
				shift
				;;
			--output*)
				export OUTPUT=`echo $1 | sed -e 's/^[^=]*=//g'`
				if [ "$OUTPUT" != "text" ] && [ "$OUTPUT" != "yaml" ] && [ "$OUTPUT" != "json" ]; then
					exit_with_help "$msg"
				fi
				shift
				;;
			*)
				if [[ -z $RELEASE ]]; then
					RELEASE=$1
				else
					exit_with_help "$msg"
				fi
				shift
				;;
		esac
	done
	if [[ -z $RELEASE ]]; then
		exit_with_help "$msg"
	fi

	RELEASE_STATUS=$(helm -n $NAMESPACE --kube-context=$K8S_CONTEXT status $RELEASE -o json)
	if [ $? -eq 0 ]; then
		echo $RELEASE_STATUS | jq > $(dirname -- "$0")/data/release-$RELEASE-status.json;
		VERSION=$(cat $(dirname -- "$0")/data/release-$RELEASE-status.json | jq -r .version)

		RELEASE_CONTENT=$(kubectl \
				get secrets sh.helm.release.v1.$RELEASE.v$VERSION \
				-n $NAMESPACE \
				--context=$K8S_CONTEXT \
				-o jsonpath='{.data.release}' \
				| base64 -d | base64 -d | gzip -d | jq | tee $(dirname -- "$0")/data/release-$RELEASE-content.json)

		CHART_NAME=$(cat $(dirname -- "$0")/data/release-$RELEASE-content.json | jq -r .chart.metadata.name)
		CHART_VERSION=$(cat $(dirname -- "$0")/data/release-$RELEASE-content.json | jq -r .chart.metadata.version)
		CHART_DIR_NAME="$CHART_NAME-$CHART_VERSION"
		CHART_DIR="$DESTINATION_DIR/$CHART_DIR_NAME"

		mkdir -p $CHART_DIR

		echo $RELEASE_CONTENT | jq -r '.chart.metadata' | $HELM_PLUGIN_DIR/lib/yq e -P - > $CHART_DIR/Chart.yaml
		echo $RELEASE_CONTENT | jq -r '.chart.values' | $HELM_PLUGIN_DIR/lib/yq e -P - > $CHART_DIR/values.yaml

		# Create Chart Templates
		for row in $(echo $RELEASE_CONTENT | jq -r '.chart.templates[] | @base64'); do
			#echo $row
			_jq() {
				echo ${row} | base64 --decode | jq -r ${1}
			}
			filename=$(echo $(_jq '.name'))
			data=$(echo $(_jq '.data') )
			mkdir -p $(dirname $CHART_DIR/$filename)
			echo $data | base64 -d > $CHART_DIR/$filename
		done
		# Create Chart files
		for row in $(echo $RELEASE_CONTENT | jq -r '.chart.files[] | @base64'); do
			#echo $row
			_jq() {
				echo ${row} | base64 --decode | jq -r ${1}
			}
			filename=$(echo $(_jq '.name'))
			data=$(echo $(_jq '.data') )
			mkdir -p $(dirname $CHART_DIR/$filename)
			echo $data | base64 -d > $CHART_DIR/$filename
		done
	fi
	rm_dir './data'
	case $OUTPUT in
		json)
			echo "{\"chart_directory\": \"$CHART_DIR_NAME\"}" ;;
		yaml)
			echo "chart_directory: $CHART_DIR_NAME" ;;
		*)
			echo "Chart saved to $CHART_DIR_NAME" ;;
	esac
	return 0;
}
