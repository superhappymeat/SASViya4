#!/usr/bin/env bash

# Based on https://github.com/doitintl/safescrub
#
# USAGE:
#
# export SA_KEY_FILE="$HOME/.viya4-tf-gcp-service-account.json"
# export GCP_PROJECT="sas-gelsandbox"
# export STUDENT=raphpoumar
# ./scripts/gcp-gen-deletion-script.sh  -k ${SA_KEY_FILE} -p ${GCP_PROJECT} -s ${STUDENT}> /tmp/todelete.sh

# examples:

# # container cluster
# gcloud container clusters list --filter="name:${STUDENT}" --verbosity error

# # compute instances
# # note, later we will use "*" in the filter
# gcloud compute instances list --filter="name:${STUDENT}" --verbosity error

# # compute adresses
# gcloud compute addresses list --filter="name:${STUDENT}*"

# # compute routes
# gcloud compute routes list --filter="network:${STUDENT}*"


usage() {
  local this_script supported

  cat <<EOD >&2
Usage:
./generate-deletion-script -s studentid -p my-project [-k project-viewer-credentials.json] [-f filter-expression] [-q true]"
  -s Student ID
  -p Project id or account
  -f (Optional.) Filter expression. The default is no filtering. Run gcloud topics filter for documentation. This filter is not supported on Google Storage buckets except for single key=value  label filters (in the form "labels.key=val").
  -k (Optional.) Filename for credentials file. The default value is project-viewer-credentials.json.
  -q quiet (no ERROR message : verbosity "none")
  -h Help. Prints this usage text.
You can direct output to create your deletion script, as for example by  suffixing
       > deletion-script.sh  && chmod a+x deletion-script.sh

EOD
  exit 1
}


while getopts 's:k:p:q:f' OPTION; do
  case "$OPTION" in
  s)
    student="$OPTARG"
    ;;
  k)
    key_file="$OPTARG"
    ;;
  p)
    project_id="$OPTARG"
    ;;
  q)
    isquiet="$OPTARG"
    echo >&2 "isquiet" "${isquiet}"
    ;;
  f)
    filter="$OPTARG"
    # Trim leading and trailing whitespace
    filter=$(echo "${filter}" | sed 's/ *$//g' | sed 's/^ *//')
    ;;
  ?)
    usage
    ;;
  esac
done

create_deletion_code() {
  local resource_types_array resource_types gcloud_component resources resources_array resource filter optiontoremoveerror isquiet
  gcloud_component=$1
  resource_types=$2
  use_uri_in_list_command=$3
  filter=$4
  isquiet=$5

  if [ "${isquiet}" == "true" ]; then
    optiontoremoveerror="--verbosity none"
  else
    optiontoremoveerror=""
  fi

  echo >&2 "verbosity:" ${optiontoremoveerror}

  if [ "${use_uri_in_list_command}" == "true" ]; then
    identifier_option="--uri"
  elif [ "${use_uri_in_list_command}" == "email" ]; then
    identifier_option="--format=table[no-heading](email)"
  else
    identifier_option="--format=table[no-heading](name)"
  fi
  if [ -z "${resource_types}" ]; then
    resource_types_array=("")
  else
    # shellcheck disable=SC2207
    resource_types_array=($(echo "$resource_types" | tr ',' '\n'))
  fi
  for resource_type in "${resource_types_array[@]}"; do
    echo >&2 "Listing ${gcloud_component} ${resource_type} with ${filter}"

    # No double-quote around ${resource} type, because it may be an empty string. If so, we wish to omit it rather than treat it as a real param with empty value.
    # shellcheck disable=SC2086

    # filter to personnlize depending on object

    #echo "$(gcloud -q "${gcloud_component}" ${resource_type} list --filter "${filter}" "${identifier_option}" --verbosity error)"

    resources="$(gcloud -q "${gcloud_component}" ${resource_type} list --filter "${filter}" "${identifier_option}" --verbosity error)"
    echo >&2 "gcloud query:  gcloud -q ${gcloud_component} ${resource_type} list --filter ${filter} ${identifier_option} --verbosity error"
    resources_array=()
    # shellcheck disable=SC2207
    resources_array=($(echo "$resources" | tr ' ' '\n'))
    if [ -n "${resources}" ]; then
      echo >&2 "Listed ${#resources_array[@]} ${gcloud_component} ${resource_type} ${filter}"
    fi
    for resource in "${resources_array[@]}"; do
      extra_flag=""
      extra_flagvalue=""

      # This is special code for clusters, the only resource which requires regional/zonal values that we now support.
      # The code should be refactored as we support more regional/zonal commands.
      #
      # We list clusters with --uri in order to parse out that region/zone value.
      # However, regional clusters cannot be deleted by full URI, so we replace the URI with resource name.
      if [ "${resource_type}" == "clusters" ]; then
        if [[ "${resource}" =~ "zones" ]]; then
          extra_flag="--zone"
          extra_flagvalue=$(echo "${resource}" | grep -o 'zones\/[a-z1-9-].*\/clusters' | cut -d'/' -f 2)
          # Zonal clusters can be deleted by URI, but there is a bug with regional so we keep it consistent
          resource=$(echo "${resource}"| rev | cut -d'/' -f 1| rev)
        fi
        if [[ "${resource}" =~ "locations" ]]; then
          extra_flag="--region"
          extra_flagvalue=$(echo "${resource}" | grep -o 'locations\/[a-z0-9-].*\/clusters' | cut -d'/' -f 2)
          # The delete command cannot accept the full URI for regional clusters
          resource=$(echo "${resource}"| rev | cut -d'/' -f 1| rev)
        fi
      fi

      # No double-quote around ${resource} type because it may be an empty string and so a param that we wish to omit rather than treat as a param with value ""
      echo "gcloud ${gcloud_component} ${resource_type} delete --project ${project_id} -q ${resource} ${extra_flag} ${extra_flagvalue} ${optiontoremoveerror}"
    done
  done

}

create_deletion_code_sub() {
  local resource_type gcloud_component resources resources_array resource filter sub_resource_type parent
  gcloud_component=$1 # compute
  resource_type=$2 # networks
  sub_resource_type=$3 # peerings
  parent=$4 # network
  filter=$5 # filter (STUDENT)

  #identifier_option="--format=value(${identifier})"

  # get parent value
  parent_value=$(gcloud compute networks list --filter="${filter}" --format="value(name)")
  echo >&2 "parent value:" $parent_value
  echo >&2 "Listing ${gcloud_component} ${resource_type} ${sub_resource_type} with ${parent} ${parent_value}"

  #resources=$(gcloud "${gcloud_component}" ${resource_type} ${sub_resource_type} list --${parent}=\""${parent_value}"\" "${identifier_option}")
  #resources=$(gcloud compute networks peerings list --network="raphpoumarv4-vpc" | awk '{print $1}' | grep -v "NAME")
  #tricky line :(
  resources=$(gcloud ${gcloud_component} ${resource_type} ${sub_resource_type} list --${parent}="${parent_value}" | awk '{print $1}' | grep -v "NAME")
  resources_array=()
  # shellcheck disable=SC2207
  resources_array=($(echo "$resources" | tr ';' '\n'))
  if [ -n "${resources}" ]; then
    echo >&2 "Listed ${#resources_array[@]} ${gcloud_component} ${resource_type} ${sub_resource_type} ${filter}"
  fi
  for resource in "${resources_array[@]}"; do
    echo >&2 "${resource}"
    # No double-quote around ${resource} type because it may be an empty string and so a param that we wish to omit rather than treat as a param with value ""
    echo "gcloud ${gcloud_component} ${resource_type} ${sub_resource_type} delete --project ${project_id} -q ${resource} --${parent}=\""${parent_value}"\" ${async_ampersand}"
  done
}

create_deletion_code_3levs() {
  local resource_types_array resource_types gcloud_component resources resources_array resource filter lev3
  gcloud_component=$1
  resource_types=$2
  lev3=$3
  use_uri_in_list_command=$4
  filter=$5

  if [ "${use_uri_in_list_command}" == "true" ]; then
    identifier_option="--uri"
  else
    identifier_option="--format=table[no-heading](name)"
  fi
  if [ -z "${resource_types}" ]; then
    resource_types_array=("")
  else
    # shellcheck disable=SC2207
    resource_types_array=($(echo "$resource_types" | tr ',' '\n'))
  fi
  for resource_type in "${resource_types_array[@]}"; do
    echo >&2 "Listing ${gcloud_component} ${resource_type} ${lev3} with ${filter}"

    # No double-quote around ${resource} type, because it may be an empty string. If so, we wish to omit it rather than treat it as a real param with empty value.
    # shellcheck disable=SC2086

    # filter to personnlize depending on object

    #echo "$(gcloud -q "${gcloud_component}" ${resource_type} list --filter "${filter}" "${identifier_option}" --verbosity error)"

    resources="$(gcloud -q "${gcloud_component}" ${resource_type} ${lev3} list --filter "${filter}" "${identifier_option}" --verbosity error)"
    resources_array=()
    # shellcheck disable=SC2207
    resources_array=($(echo "$resources" | tr ' ' '\n'))
    if [ -n "${resources}" ]; then
      echo >&2 "Listed ${#resources_array[@]} ${gcloud_component} ${resource_type} ${lev3} ${filter}"
    fi
    for resource in "${resources_array[@]}"; do
      # No double-quote around ${resource} type because it may be an empty string and so a param that we wish to omit rather than treat as a param with value ""
      echo "gcloud ${gcloud_component} ${resource_type} ${lev3} delete --project ${project_id} -q ${resource}"
    done
  done

}

# let's call our deletion loop

echo >&2  "working on the GKE cluster"
# deleting a K8s Cluster does not delete everything: https://cloud.google.com/kubernetes-engine/docs/how-to/deleting-a-cluster
export FILTER="name:${student}"
create_deletion_code container clusters "true" "${FILTER}"

echo >&2  "working on a lot of compute_resource_types"
export FILTER="name:${student}"
# compute_resource_types="instances addresses target-http-proxies target-https-proxies target-grpc-proxies url-maps backend-services firewall-rules forwarding-rules health-checks http-health-checks https-health-checks instance-templates networks routers target-pools target-tcp-proxies"
compute_resource_types="routers,addresses,target-http-proxies, target-https-proxies,target-grpc-proxies,url-maps,backend-services,forwarding-rules,health-checks,http-health-checks,https-health-checks,instance-templates,target-pools,target-tcp-proxies"
create_deletion_code compute "${compute_resource_types}" "true" "${FILTER}"

# TODO : maybe remove GKE instances, vpc-nat-ip adress, disks as they are removed by GEL cluster removal

echo >&2  "working on non GKE instances"
export FILTER="name:${student} AND name:jump-server"
create_deletion_code compute instances "true" "${FILTER}"


echo >&2  "working on firewall-rules"
export FILTER="name:${student}*"
create_deletion_code compute firewall-rules "true" "${FILTER}" "${isquiet}"

# VPC Networks can only be deleted when no other resources (e.g., virtual machine instances) refer to them. https://cloud.google.com/sdk/gcloud/reference/compute/networks/delete
echo >&2 "working on NETWORK sub-resources"
# first remove vpc sub-resources
export FILTER="name:${student}*"
# peerings
create_deletion_code_sub compute networks peerings network "${FILTER}"

echo >&2  "working on routes"
export FILTER="network:${student}*"
create_deletion_code compute routes "true" "${FILTER}" "${isquiet}"

echo >&2  "working on SQL instance"
export FILTER="name:${student}"
create_deletion_code sql instances "false" "${FILTER}"

echo >&2  "working on filestore"
export FILTER="name:${student}"
create_deletion_code filestore instances "true" "${FILTER}"

# subnets
#create_deletion_code compute subnet "true" "${FILTER}"
# DOES NOT WORK target : gcloud compute networks subnets delete --project sas-gelsandbox -q raphpoumarv4-vpc-subnet
# TODO: test the below
export FILTER="name:${student}*"
create_deletion_code_3levs compute networks subnets "true" "${FILTER}"

# delete vpc
export FILTER="name:${student}*"
create_deletion_code compute networks "true" "${FILTER}"
# fails with:
# - The network resource 'projects/sas-gelsandbox/global/networks/raphpoumarv4-vpc' is already being used by 'projects/sas-gelsandbox/global/firewalls/raphpoumarv4-jump-server-firewall'
# TODO: TEST AGAIN (firewall ruls delete improved)

# delete disks (remaining GKE-disks)
export FILTER="name:${student}"
# We do it in "quiet" mode to avoid deletin ERROR in case they are already gone.
create_deletion_code compute disks "true" "${FILTER}" "${isquiet}"

# delete service accounts
export FILTER="name:${student} AND name:tf"
# We do it in "quiet" mode to avoid deletin ERROR in case they are already gone.
create_deletion_code iam service-accounts "email" "${FILTER}"


echo >&2 "working on LOADBALANCER"
# Loadbalancer cleanup: https://cloud.google.com/load-balancing/docs/cleaning-up-lb-setup, https://stackoverflow.com/questions/48930737/how-to-delete-load-balancer-using-gcloud-command
# many thing removed from the compute_resource_types array

#gcloud compute backend-services delete [BACKEND_SERVICE]
# done by generic command above ?

#gcloud compute target-${PROTOCOL}-proxies delete [TARGET_PROXY]
# done by generic command above ?

#gcloud compute forwarding-rules delete [FORWARDING_RULE]
# done by generic command above ?

#gcloud compute addresses delete [IP_ADDRESS]
# done by generic command above ?

#gcloud compute health-checks delete [HEALTH_CHECK]
# done by generic command above ?

#gcloud compute url-maps delete [URL_MAP]
# done by generic command above ?
