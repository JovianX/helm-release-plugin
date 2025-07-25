#!/usr/bin/env bash

function exit_with_help() { printf '%s\n' "$1" && exit_script; }

function get_timestamp() { printf $(date '+%Y-%m-%d_%H%M%S'); }

function init_dir() { [[ -d $_ROOT'/'$1 ]] || mkdir $_ROOT'/'$1; }

function rm_dir() { [[ -d $_ROOT'/'$1 ]] || rm -rf $_ROOT'/'$1; }

function test_deps() {
	if ! command -v jq &> /dev/null
	then
		echo "jq could not be found - please install command `jq` (https://stedolan.github.io/jq/download/)"
		exit
	fi


	if ! date --utc +%s > /dev/null 2>&1; then
		if ! command -v gdate &> /dev/null; then
			echo "gdate could not be found - please install command `gdate` (https://www.gnu.org/software/coreutils/)"
			echo "If you are on macOS, you can install it using Homebrew: `brew install coreutils`"
			exit
		else
			alias date='gdate'
		fi
	fi

}

function str_split() {
	declare -a -x -g str_split_result=()
	IFS="$2"; read -ra str_split_result <<< $1; IFS=' '
}