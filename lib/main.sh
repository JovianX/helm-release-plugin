#!/usr/bin/env bash
source $(dirname -- "$0")/lib/config.sh
source $(dirname -- "$0")/lib/utility.sh
source $(dirname -- "$0")/lib/api/helm-ops.sh
source $(dirname -- "$0")/lib/api/upgrade.sh

function main() {

	init_dir './data'
	test_deps

	COMMANDS='[
		{"pull":	"pull_chart_from_release"},
		{"upgrade":	"upgrade_release"}
		]'


	COMMAND_NAMES=$(echo $COMMANDS | jq -r '.[]| keys[] as $k| $k ')


	local msg="usage: helm release [$COMMAND_NAMES]"
	if [[ $# < 1 ]]; then exit_with_help "$msg"; fi

	local COMMAND=${1}; shift


	# echo $COMMANDS | jq -c '.[]' | while read i; do
	#     echo " "
	# 	#echo $i
	#     #echo key: $(echo $i | jq -r 'keys[]')
	#     #echo value: $(echo $i | jq -r '.[]')
	# done

	COMMAND_FUNCTION=$(echo $COMMANDS | jq  -qrc ".[]| .$COMMAND" | grep -v null)
	#echo $COMMAND
	echo $COMMAND_FUNCTION

	# Show exit message when command was not provided
	if [[ $COMMAND_FUNCTION == '' ]]; then exit_with_help "$msg"; fi

	# Remove data dir
	rm -Rf $(dirname -- "$0")/data;
}