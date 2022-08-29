#!/usr/bin/env bash
source $(dirname -- "$0")/lib/config.sh
source $(dirname -- "$0")/lib/utility.sh
source $(dirname -- "$0")/lib/api/helm-ops.sh
source $(dirname -- "$0")/lib/api/upgrade.sh
source $(dirname -- "$0")/lib/api/ttl.sh


function main() {
	init_dir './data'
	test_deps

	declare -A -x command_table=(
		['pull']="pull_chart_from_release"
		['upgrade']="upgrade_release"
		['ttl']="release_ttl"
	)

	local commands="${!command_table[@]}"
	local msg="usage: helm release [ $commands ]"
	if [[ $# < 1 ]]; then exit_with_help "$msg"; fi

	local command=${1}; shift
	local fn_name=${command_table[$command]}

	if [[ $fn_name == '' ]]; then exit_with_help "$msg"; fi
	if $fn_name "$@"; then
		rm -Rf $(dirname -- "$0")/data;
		return 0;
	else
		return 1;
	fi
}