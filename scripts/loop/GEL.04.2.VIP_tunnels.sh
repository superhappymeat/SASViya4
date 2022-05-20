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


case "$1" in
    'enable')


    ;;
    'start')

        ## RKE
        if  [ "$collection_size" -gt "2"  ] ; then
            logit "We are running on a multi-machine collection with $collection_size servers"

            logit "Setting up VIP tunnels"

            if [ "$race_alias" == "sasnode01" ]  ; then
               logit "on sasnode01"


                ## if there is a mismatch in # of machines, then ...
                ##  also do the "guessing " routine

                sudo -u cloud-user bash -c "ansible sasnode* -m ping"

                # if it failed
                if [ $? -eq 0 ]
                then
                    echo "all sasnodes respond to ping"

                else
                    echo "One or more sasnode is not reachable"

                    ansible sasnode*,localhost -b -m shell -a \
                        'cat /etc/hosts /etc/hosts.*' \
                        |  grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b.*sasnode[0-9]{2}.*$" \
                        | sed 's/n\-t\-i\-e\-r.*$//g' \
                        | sort -u \
                        | tee /tmp/good_hosts.txt

                    ansible sasnode*,localhost -m blockinfile -b \
                        -a "dest=/etc/hosts \
                            block=\"{{ lookup('file', '/tmp/good_hosts.txt') }}\"  \
                            backup=yes \
                            insertafter=EOF \
                            marker=\"# {mark} last-ditch effort on IPs \"  \
                            " \
                            --diff

                    ansible sasnode*,localhost -m blockinfile -b \
                        -a "dest=/etc/hosts \
                            block=\"{{ lookup('file', '/tmp/good_hosts.txt') }}\"  \
                            backup=yes \
                            insertafter=EOF \
                            marker=\"# {mark} last-ditch effort on IPs \"  \
                            " \
                            --diff

                fi



                if [ "$on_azure" == "1" ]  ; then
                    logit "on azure, so, no tunnels"

                    logit "Fixing hostnames to match with hard-coded 'int' names"

                    # sudo -u cloud-user bash -c \
                    #     "rm -f ~/.ansible/roles ; \
                    #     ln -s  /opt/raceutils/ansible/roles ~/.ansible/roles "
                        # ln -s  /home/cloud-user/PSGEL255-deploying-viya-4.0.1-on-kubernetes/scripts/playbooks/roles ~/.ansible/roles "

                    sudo -u cloud-user bash -c \
                        "ansible-playbook ~/PSGEL255-deploying-viya-4.0.1-on-kubernetes/scripts/playbooks/set_azu_hostnames.yaml --diff "

                else
                    logit "on vmware, so, setting up tunnels"


                    sudo -u cloud-user bash -c \
                        "rm -f ~/.ansible/roles ; \
                        ln -s  /home/cloud-user/PSGEL255-deploying-viya-4.0.1-on-kubernetes/scripts/playbooks/roles ~/.ansible/roles "

                    sudo -u cloud-user bash -c \
                        "ansible-playbook ~/PSGEL255-deploying-viya-4.0.1-on-kubernetes/scripts/playbooks/VIP_tunnels.yaml "

                    if [ $? -eq 0 ]
                    then
                        logit "VIP Tunnels seem to have worked! Continuing!"
                    else
                        logit "VIP Tunnels seem to have failed on first try! Trying to fix up RACE and try again!"

                        # logit "Updating the /etc/host based on the first machine"
                        # sudo -u cloud-user bash -c \
                        #     "ansible sasnode* -m copy -b \
                        #         -a 'src=/etc/hosts \
                        #             dest=/etc/hosts \
                        #             owner=root \
                        #             group=root \
                        #             mode=644' \
                        #     "
                        # sleep 5

                        # logit "Resetting hostnames in case it helps"
                        # sudo -u cloud-user bash -c \
                        #     "ansible-playbook ~/PSGEL255-deploying-viya-4.0.1-on-kubernetes/scripts/playbooks/set_hostnames.yaml --diff "

                        # logit "Retrying the machine identification sequence"
                        # sudo /opt/raceutils/bootstrap/loop/GEL.01.identify.sh start

                        # logit "Retrying the tunnels"
                        # sudo -u cloud-user bash -c "ansible-playbook ~/PSGEL255-deploying-viya-4.0.1-on-kubernetes/scripts/playbooks/VIP_tunnels.yaml"

                        # if [ $? -eq 0 ]
                        # then
                        #     logit "VIP Tunnels seem to have worked ON SECOND TRY! Continuing!"
                        # else
                            logit "VIP Tunnels seem to have failed again! We are giving up now."
                            logit "IMPORTANT: DO NOT WAIT, THIS WILL NOT GET BETTER."
                            logit "IMPORTANT: Cancel this collection and get a new one going."
                            sleep 10000000
                        # fi

                    fi

                fi

            fi
        fi

    ;;
    'stop')

    ;;
    'clean')

    ;;

    *)
        printf "Usage: GEL.04.2VIP.sh {enable/start|stop|clean} \n"
        exit 1
    ;;
esac

