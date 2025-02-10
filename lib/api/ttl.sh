#!/usr/bin/env bash

HELM_VERSION="3.10.2"
KUBECTL_VERSION="1.26.1"

help_text="
Sets release TTL. Under the hood creates Kubernetes CronJob that will delete specific release in concrete time.
Usage:
	helm release ttl <RELEASE NAME> --set <TIME DELTA> - sets release TTL. Time delta processed by 'date' CLI utility.
		So you can use any time delta definition that supports 'data' utility. Examples:
		helm release ttl redis --set='tomorrow'
		helm release ttl redis --set='2 days'
		helm release ttl redis --set='next monday'
		For detailed description please reference to 'date' CLI utility documentation:
		https://www.gnu.org/software/coreutils/manual/html_node/Relative-items-in-date-strings.html

		You can pass namespace or/and context. For instance:
		helm release ttl redis --namespace=release-namespace --kube-context=not-default-context --set='1 hour'

		It is recommended to create a special service account (instead of granting the default service account special privileges)
		helm release ttl redis --namespace=release-namespace --service-account='my-service-account' --set='1 hour'

		This service account will be used in the job when the ttl time expires and the cleanup is triggered.

	helm release ttl <RELEASE NAME> [ -o --output [ text | yaml | json ] ] - returns Kubernetes CronJob description.
		Examples:
		helm release ttl redis --namespace=release-namespace
		helm release ttl redis --namespace=release-namespace

		You can specify output format text(default) yaml or json. For example:
		helm release ttl redis --namespace=release-namespace --output=yaml
		helm release ttl redis --namespace=release-namespace -o json
		Output examples:
		text: Scheduled release removal date: Tue Aug 30 14:44:00 EEST 2022
		yaml: scheduled_date: 2022-08-30 14:44
		json: {\"scheduled_date\": \"2022-08-30 14:44\"}


	helm release ttl <RELEASE NAME> --unset - deletes release TTL. For instance:
		helm release ttl --namespace=release-namespace redis --unset
"

function create_ttl() {
	RELEASE=$1
	TIME_DELTA=$2
	SERVICE_ACCOUNT=$3
	cronjob_name="$RELEASE-ttl"
	now=$(date --utc "+%s")
	scheduled_time=$(date --utc --date="$TIME_DELTA" "+%s")
	schedule=$(date --utc --date="$TIME_DELTA" "+%M %H %d %m *")

	if (( scheduled_time < now )); then
		printf '%s\n' 'Release TTL was set in past. TTL must be a future time.'
		exit_with_help "$help_text"
	fi

	assert_serviceaccount_exits $HELM_NAMESPACE $SERVICE_ACCOUNT

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
                      image: alpine/helm:$HELM_VERSION
                      imagePullPolicy: IfNotPresent
                      args: [ 'uninstall', '$RELEASE' ]
                  containers:
                    - name: release-ttl-cleaner
                      image: bitnami/kubectl:$KUBECTL_VERSION
                      imagePullPolicy: IfNotPresent
                      args: [ 'delete', 'cronjob', '$cronjob_name' ]
                  restartPolicy: OnFailure
                  serviceAccountName: $SERVICE_ACCOUNT"
	echo "$manifest" | kubectl apply --filename=- --namespace=$HELM_NAMESPACE --context=$HELM_KUBECONTEXT
}

function assert_serviceaccount_exits() {
	namespace=$1
	service_account=$2

	service_accounts=`kubectl get serviceaccounts --output=json --namespace=$1 | jq -r '.items[].metadata.name'`  # Fetching list of service accounts.
	array=(${service_accounts})  # Converting it to array.

	if [[ ${array[*]} =~ ${service_account} ]]; then  # 'contains' if condition example.
		printf "Service account list contains '$service_account'.\n"
	fi

	if [[ ! ${array[*]} =~ ${service_account} ]]; then  # 'not contains' if condition example
		printf "Service account list does not contains '$service_account'.\n"
		printf "Available service accounts: ${array[*]}\n"
		exit_with_help "$help_text"
	fi
}

function read_ttl() {
	RELEASE=$1
	cronjob_name="$RELEASE-ttl"
	cronjob_json=$(kubectl get cronjob $cronjob_name --output=json --namespace=$HELM_NAMESPACE --context=$HELM_KUBECONTEXT)
	if [[ -z $cronjob_json ]]; then
		exit 1
	fi
	schedule=$(echo $cronjob_json | jq -r .spec.schedule)
	minutes=${schedule:0:2}
	hours=${schedule:3:2}
	day=${schedule:6:2}
	month=${schedule:9:2}
	year=$(date +'%Y')

	case $OUTPUT in
		(json)
			printf "{\"scheduled_date\": \"%s\"}\n" "$year-$month-$day $hours:$minutes" ;;
		(yaml)
			printf "scheduled_date: %s\n" "$year-$month-$day $hours:$minutes" ;;
		(*)
			release_removal_date=$(date --date="$year-$month-$day $hours:$minutes")
			printf "Scheduled release removal date: %s\n" "$release_removal_date" ;;
	esac
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
	OUTPUT="text"
	SERVICE_ACCOUNT="default"

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
			(-o|--output)
				shift
				if test $# -gt 0; then
					export OUTPUT=$1
					if [ "$OUTPUT" != "text" ] && [ "$OUTPUT" != "yaml" ] && [ "$OUTPUT" != "json" ]; then
						exit_with_help "$help_text"
					fi
				else
					exit_with_help "$help_text"
				fi
				shift
				;;
			(--output*)
				export OUTPUT=`echo $1 | sed -e 's/^[^=]*=//g'`
				if [ "$OUTPUT" != "text" ] && [ "$OUTPUT" != "yaml" ] && [ "$OUTPUT" != "json" ]; then
					exit_with_help "$help_text"
				fi
				shift
				;;
			(--service-account*)
				SERVICE_ACCOUNT=`echo $1 | sed -e 's/^[^=]*=//g'`
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
			create_ttl $RELEASE "$SET_DATE" "$SERVICE_ACCOUNT"
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
