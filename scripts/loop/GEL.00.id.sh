#!/bin/bash

timestamp() {
  date +"%T"
}
datestamp() {
  date +"%D"
}

function logit () {
    sudo touch ${RACEUTILS_PATH}/logs/${HOSTNAME}.bootstrap.log
    sudo chmod 777 ${RACEUTILS_PATH}/logs/${HOSTNAME}.bootstrap.log
    printf "$(datestamp) $(timestamp): $1 \n"  | tee -a ${RACEUTILS_PATH}/logs/${HOSTNAME}.bootstrap.log
}

## Read in the id file. only really needed if running these scripts in standalone mode.
source <( cat /opt/raceutils/.bootstrap.txt  )
source <( cat /opt/raceutils/.id.txt  )
reboot_count=$(cat /opt/raceutils/.reboot.txt)

logit "Reboot Count is $reboot_count "

id_file=${RACEUTILS_PATH}/.id.txt
bootstrap_file=${RACEUTILS_PATH}/.bootstrap.txt

# if [ "$reboot_count" -le "1" ] ; then
#     logit "because reboot count is $reboot_count, all the start sections will fire"
# fi
# if [ "$reboot_count" -gt "1" ] ; then
#     logit "because reboot count is $reboot_count , we won't re-do quite everything"
# fi

case "$1" in
    'enable')
        printf "Doing the enable\n"

    ;;
    'start')
        printf "Start of id sequence\n"

        # are we on Azure?
        curl -H Metadata:true \
            --max-time 5 \
            --noproxy \
            "*" \
            "http://169.254.169.254/metadata/"

        if [ $? -eq 0 ]
        then
            printf "This is an Azure machine\n"

            ## add the info:
            echo "on_azure=1"       | sudo tee -a ${id_file}
            curl -H Metadata:true \
            --noproxy \
            "*" \
            "http://169.254.169.254/metadata/instance?api-version=2020-09-01" \
            | jq \
            | sudo tee /opt/raceutils/.azure_details

            sudo sed -i 's/intnode/sasnode/g' /opt/raceutils/.id.txt

        else
            printf "This is NOT an Azure machine\n"
            ## add the info:
            echo "on_azure=0"       | sudo tee -a ${id_file}

        fi

        # Override the branch, if passed as a comment in the form:
        # _BRANCH_my_branch_name_   (with a space at the end)
        echo ${description}

        ## example of description:
        ## description="C3 _AUTODEPLOY_LTS_ _BRANCH_azu_coll_fixes_ Deployment"
        if [[ "$description" == *"_BRANCH_"* ]]  ; then
            OVERRIDE_BRANCH=$(echo ${description} \
                | grep -o -P "_BRANCH_.*?_( |$)"  \
                | sed 's/_BRANCH_\(.*\)_/\1/g' \
                )
            echo ${OVERRIDE_BRANCH}

            logit "Overriding the default branch to ${OVERRIDE_BRANCH}, due to a collection comment  "

            echo "## Overriding the default branch to '${OVERRIDE_BRANCH}', due to a collection comment  "  | sudo tee -a ${bootstrap_file}
            echo "BRANCH=${OVERRIDE_BRANCH}"       | sudo tee -a ${bootstrap_file}

            cd /tmp/testclone
            sudo git config remote.origin.fetch "+refs/heads/*:refs/remotes/origin/*"
            sudo git fetch origin
            sudo git fetch --all
            sudo git pull --all
            sudo git stash save "get rid of garbage"
            sudo git checkout  ${OVERRIDE_BRANCH}

        fi

    ;;
    'stop')

    ;;
    'clean')

    ;;

    *)
        printf "Usage: GEL.00.id.sh {enable/start|stop|clean} \n"
        exit 1
    ;;
esac

