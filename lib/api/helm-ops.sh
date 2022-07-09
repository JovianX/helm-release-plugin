#!/usr/bin/env bash
function pull_chart_from_release() {
	local msg="usage: helm release pull <RELEASE NAME>"
	if [[ $# < 1 ]]; then exit_with_help "$msg"; fi

	RELEASE=$1
	NAMESPACE=$HELM_NAMESPACE

	RELEASE_STATUS=$(helm -n $NAMESPACE  status $RELEASE -o json)
	if [ $? -eq 0 ]; then
		echo $RELEASE_STATUS | jq > $(dirname -- "$0")/data/release-$RELEASE-status.json;
		VERSION=$(cat $(dirname -- "$0")/data/release-$RELEASE-status.json | jq -r .version)

		RELEASE_CONTENT=$(kubectl \
		 		get secrets sh.helm.release.v1.$RELEASE.v$VERSION \
				-n $NAMESPACE \
				-o jsonpath='{.data.release}' \
				| base64 -d | base64 -d | gzip -d | jq | tee $(dirname -- "$0")/data/release-$RELEASE-content.json)

		CHART_NAME=$(cat $(dirname -- "$0")/data/release-$RELEASE-content.json | jq -r .chart.metadata.name)
		CHART_VERSION=$(cat $(dirname -- "$0")/data/release-$RELEASE-content.json | jq -r .chart.metadata.version)
		CHART_DIR=$CHART_NAME-$CHART_VERSION

		mkdir -p $CHART_DIR

 		# sudo wget https://github.com/mikefarah/yq/releases/download/v4.25.3/yq_linux_amd64  -O /usr/bin/yq
		echo $RELEASE_CONTENT  |  jq -r '.chart.metadata' | yq e -P - > $CHART_DIR/Chart.yaml
		echo $RELEASE_CONTENT  |  jq -r '.chart.values' | yq e -P - > $CHART_DIR/values.yaml

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
	return 0;
}