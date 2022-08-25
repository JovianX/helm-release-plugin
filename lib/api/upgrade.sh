#!/usr/bin/env bash

help_text="Update release values without specifying the Helm Chart.
Usage: helm release upgrade [RELEASE NAME] [-d | --destination <TARGET CHART DIRECTORY>] [helm upgrade arguments]"

function upgrade_release() {
	RELEASE=$1
	shift
	if [[ -z $RELEASE ]]; then
        printf '%s\n' 'No release was provided.'
		exit_with_help "$help_text"
	fi
	chart_destination='/tmp'
	update_arguments=()
	for (( i=1; i<=$#; i++ ));
	do
		case "${!i}" in
			(-d|--destination)
				next=$((i+1))
				if [[ -z "${!next}" ]]; then
					printf '%s\n' 'No destination was provided.'
					exit_with_help "$help_text"
				fi
				chart_destination="${!next}"
				;;
			(--destination*)
				chart_destination=`echo "${!i}" | sed -e 's/^[^=]*=//g'`
				;;
			(-h|--help)
				exit_with_help "$help_text"
				;;
			(*)
				update_arguments[${#update_arguments[@]}]="${!i}"
				;;
		esac
	done

	chart_directory=$(helm release pull $RELEASE --destination=$chart_destination --output=json | jq -r .chart_directory)
	if [[ -z $chart_directory ]]; then
		printf '%s\n' 'Failed to get release chart.'
		return 1;
	fi
	chart_path="$chart_destination/$chart_directory"

	helm dependency build $chart_path
	helm upgrade "$RELEASE" "$chart_path" "${update_arguments[@]}"

	rm -rf $chart_path

	return 0;
}
