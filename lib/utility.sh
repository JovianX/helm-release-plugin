#!/usr/bin/env bash

function exit_with_help() { echo $1 && exit_script; }

function get_timestamp() { printf $(date '+%Y-%m-%d_%H%M%S');  }

function init_dir() { [[ -d $_ROOT'/'$1 ]] || mkdir $_ROOT'/'$1; }

function rm_dir() { [[ -d $_ROOT'/'$1 ]] || rm -rf $_ROOT'/'$1; }

function str_split() {

	declare -a -x -g str_split_result=()
	IFS="$2"; read -ra str_split_result <<< $1; IFS=' '
}