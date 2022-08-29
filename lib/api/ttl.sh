#!/usr/bin/env bash

help_text="
Sets release TTL. Under the hood creates Kubernetes CronJob that will delete specific release in concrete time.
Usage:
	helm release ttl <RELEASE NAME> --set <TIME DELTA> - sets release TTL. Time delta processed by 'date' CLI utility.
		So you can use any time delta definition that supports 'data' utility. For instance:
		helm release ttl redis --set='tomorrow'
		helm release ttl redis --set='2 days'
		helm release ttl redis --set='next monday'
		For detailed description please reference to 'date' CLI utility documentation:
		https://www.gnu.org/software/coreutils/manual/html_node/Relative-items-in-date-strings.html

		You can pass namespace or/and context. For instance:
		helm release ttl redis --namespace=release-namespace --kube-context=not-default-context --set='1 hour'


	helm release ttl <RELEASE NAME> - returns Kubernetes CronJob description. For instance:
		helm release ttl redis --namespace=release-namespace


	helm release ttl <RELEASE NAME> --unset - deletes release TTL. For instance:
		helm release ttl --namespace=release-namespace redis --unset
"

function create_ttl() {
	RELEASE=$1
	TIME_DELTA=$2
	cronjob_name="$RELEASE-ttl"
	now=$(date --utc "+%s")
	scheduled_time=$(date --utc --date="$TIME_DELTA" "+%s")
	schedule=$(date --utc --date="$TIME_DELTA" "+%M %H %d %m *")

	if (( scheduled_time < now )); then
		printf '%s\n' 'Release end of life seted in past.'
		exit_with_help "$help_text"
	fi

	manifest="
        apiVersion: batch/v1
        kind: CronJob
        metadata:
          name: $cronjob_name
          namespace: $HELM_NAMESPACE
        spec:
          schedule: '$schedule'
          jobTemplate:
            spec:
              template:
                spec:
                  initContainers:
                    - name: release-ttl-terminator
                      image: alpine/helm
                      imagePullPolicy: IfNotPresent
                      args: [ 'uninstall', '$RELEASE' ]
                  containers:
                    - name: release-ttl-cleaner
                      image: bitnami/kubectl
                      imagePullPolicy: IfNotPresent
                      args: [ 'delete', 'cronjob', '$cronjob_name' ]
                  restartPolicy: OnFailure"
	echo "$manifest" | kubectl apply --filename=- --namespace=$HELM_NAMESPACE --context=$HELM_KUBECONTEXT
}

function read_ttl() {
	RELEASE=$1
	cronjob_name="$RELEASE-ttl"
	kubectl describe cronjob $cronjob_name --namespace=$HELM_NAMESPACE --context=$HELM_KUBECONTEXT || exit 0
}

function delete_ttl() {
	RELEASE=$1
	cronjob_name="$RELEASE-ttl"
	kubectl delete cronjob $cronjob_name --namespace=$HELM_NAMESPACE
}

function release_ttl() {
	RELEASE=""
	SET_DATE=""
	ACTION="read"  # Work mode. Possible options are: 'read' | 'set' | 'unset'.

	RELEASE=$1
	shift
	if [[ -z $RELEASE ]]; then
		printf '%s\n' 'No release was provided.'
		exit_with_help "$help_text"
	fi
	while test $# -gt 0; do
		case "$1" in
			(--set)
				shift
				if [[ "$ACTION" == 'unset' ]]; then
					printf '%s\n' 'Set and unset TTL was requested. Exiting...'
					exit_with_help "$help_text"
				fi
				if test $# -gt 0; then
					SET_DATE="$1"
					ACTION='set'
				else
					exit_with_help "$help_text"
				fi
					shift
				;;
			(--set*)
				if [[ "$ACTION" == 'unset' ]]; then
					printf '%s\n' 'Set and unset TTL was requested. Exiting...'
					exit_with_help "$help_text"
				fi
				SET_DATE=`echo $1 | sed -e 's/^[^=]*=//g'`
				ACTION='set'
				shift
				;;
			(--unset)
				if [[ "$ACTION" == 'set' ]]; then
					printf '%s\n' 'Set and unset TTL was requested. Exiting...'
					exit_with_help "$help_text"
				fi
				ACTION='unset'
				shift
				;;
			(--help)
				exit_with_help "$help_text"
				;;
			*)
				printf '%s\n' "Unknown argument $1. Exiting..."
				exit_with_help "$help_text"
				;;
		esac
	done

	case "$ACTION" in
			(set)
				create_ttl $RELEASE "$SET_DATE"
				;;
			(read)
				read_ttl $RELEASE
				;;
			(unset)
				delete_ttl $RELEASE
				;;
			*)
				printf '%s\n' "Unknown TTL action $ACTION."
				exit 1
				;;
		esac
}