#!/usr/bin/env bash

function exit_with_help() { echo $1 && exit_script; }

function get_timestamp() { printf $(date '+%Y-%m-%d_%H%M%S');  }

function init_dir() { [[ -d $_ROOT'/'$1 ]] || mkdir $_ROOT'/'$1; }

function rm_dir() { [[ -d $_ROOT'/'$1 ]] || rm -rf $_ROOT'/'$1; }

function test_deps() {
	if ! command -v jq &> /dev/null
	then
		echo "jq could not be found - please install command `jq` (https://stedolan.github.io/jq/download/)"
		exit
	fi
}

