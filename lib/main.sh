#!/usr/bin/env bash
source $(dirname -- "$0")/lib/config.sh
source $(dirname -- "$0")/lib/utility.sh
source $(dirname -- "$0")/lib/api/helm-ops.sh
source $(dirname -- "$0")/lib/api/upgrade.sh
source $(dirname -- "$0")/lib/api/ttl.sh


function main() {
	init_dir './data'
	test_deps

	local commands="pull upgrade ttl"
	local msg="usage: helm release [ $commands ]"
	if [[ $# < 1 ]]; then exit_with_help "$msg"; fi

	local command=${1}; shift
	local fn_name=""

	case "$command" in
		"pull")
			fn_name="pull_chart_from_release"
			;;
		"upgrade")
			fn_name="upgrade_release"
			;;
		"ttl")
			fn_name="release_ttl"
			;;
		*)
			exit_with_help "$msg"
			;;
	esac
	if $fn_name "$@"; then
		rm -Rf $(dirname -- "$0")/data;
		return 0;
	else
		return 1;
	fi
}