![Global Enablement & Learning](https://gelgitlab.race.sas.com/GEL/utilities/writing-content-in-markdown/-/raw/master/img/gel_banner_logo_tech-partners.jpg)

# Using `mirrormgr` to populate the local registry

* [Installing mirrormgr](#installing-mirrormgr)
* [working area:](#working-area)
* [pulling down and pushing images into local registry](#pulling-down-and-pushing-images-into-local-registry)
* [Verification](#verification)
* [Navigation](#navigation)

## Installing mirrormgr

<!--
1. To install it (internal version)

    ```sh
    mirrormgr_URL=https://gelweb.race.sas.com/scripts/PSGEL255/mirrormgr/mirrormgr

    ansible localhost \
        -b --become-user=root \
        -m get_url \
        -a  "url=${mirrormgr_URL} \
            dest=/usr/local/bin/mirrormgr \
            validate_certs=no \
            force=yes \
            owner=root \
            mode=0755 \
            backup=yes" \
        --diff

    ```
 -->

1. Download mirrormgr from the SAS website and install it

    <https://support.sas.com/installation/viya/4/sas-mirror-manager/>

    ```bash

    MIRRORMGR_URL=https://support.sas.com/installation/viya/4/sas-mirror-manager/lax/mirrormgr-linux.tgz

    wget   ${MIRRORMGR_URL} -O - | sudo tar -xz -C /usr/local/bin/
    sudo chmod 0755 /usr/local/bin/

    ```

1. Check version:

    ```bash
    mirrormgr --version

    ```

## working area:

1. Create a new folder:

    ```bash
    mkdir -p ~/project/deploy/mirrored
    ```

## pulling down and pushing images into local registry

1. first, we need the certs.zip or the deployment data

    ```bash
    CADENCE_NAME='stable'
    CADENCE_VERSION='2020.1.5'

    bash /opt/gellow_code/scripts/common/generate_sas_bases.sh \
          --cadence-name $CADENCE_NAME \
          --cadence-version $CADENCE_VERSION \
          --order-nickname 'full' \
          --output-folder ~/project/deploy/mirrored

    ZIP_NAME=$(ls ~/project/deploy/mirrored  | grep "\.zip")

    ```

1. Now run a few mirrormgr commands to get used to the syntax:

    ```bash
    cd  ~/project/deploy/mirrored

    ## display all the available Cadences and Versions for this order
    mirrormgr --deployment-data ${ZIP_NAME} \
        list remote cadences

    ## display all the available Versions and Releases
    mirrormgr --deployment-data ${ZIP_NAME} \
        list remote cadence releases

    mirrormgr --deployment-data ${ZIP_NAME} \
        list remote repos size --latest
    ```

1. And now, let's mirror the latest images:

    ```bash
    harbor_user=$(cat ~/exportRobot.json | jq -r .name)
    harbor_pass=$(cat ~/exportRobot.json | jq -r .token)

    #docker login harbor.$(hostname -f):443 -u ${harbor_user}  -p ${harbor_pass}

    time mirrormgr --deployment-data ~/project/deploy/mirrored/${ZIP_NAME} mirror registry \
        --destination harbor.$(hostname -f):443/viya \
        --username admin \
        --password lnxsas \
        --insecure \
        --cadence ${CADENCE_NAME}-${CADENCE_VERSION} \
        --path ~/sas_repos/ \
        --latest \
        --log-file ~/sas_repos/mirrormgr.log \
        --workers 100

    ```

* This will take a long time to run and might have errors in it.
* If so, re-run it a second time.
* If the errors persist, re-run it with `--workers 5` to see if it gets rid of the errors.

* Now, check how much space this consumed:

    ```bash
    du --max-depth=1 -h ~/sas_repos/
    # 65 GB
    sudo du --max-depth=1 -h /srv/nfs/kubedata/harbo*regist*
    # 41 GB

    ```

By mirroring with the `--latest` option, we got the latest images only. If we were to use deployment assets that are older than that, we would need to be more precise, and use the exact **release** number when mirroring the images.

1. THERE IS NO NEED TO RUN THIS.

    That's why it's commented out.

    Adding the exact release would make if very clean which version of Viya needs to be mirrored.

    ```bash

    #CADENCE_NAME='stable'
    #CADENCE_VERSION='2020.1.5'
    CADENCE_RELEASE='20210318.1616036841383'

    ```bash
    du --max-depth=1 -h ~/sas_repos/
    # 72G
    sudo du --max-depth=1 -h /srv/nfs/kubedata/harbo*regist*
    # 45G
    #time mirrormgr --deployment-data ${ZIP_NAME} mirror registry \
    #    --destination harbor.$(hostname -f):443/viya \
    #    --username ${harbor_user} \
    #    --password ${harbor_pass} \
    #    --insecure \
    #    --cadence ${CADENCE_NAME}-${CADENCE_VERSION} \
        --release ${CADENCE_RELEASE} \
    #    --path ~/sas_repo \
    #    --log-file ~/sas_repo/mirrormgr.log \
    #    --workers 100
    ```

## Verification

```sh
ansible sasnodes -m shell -a "df -h | grep sda3"
```

At this point, verify that the images are in the registry (run this command to get its url:)

```bash
cat ~/urls.md | grep -i harbor

```

Optional: delete the local copy as this uses up a lot of space:

```sh
# if you run this, it deletes the intermediary copy of the images.
# if you have to mirror again, it will be possible but longer.
rm -rf ~/sas_repos

```

<!--
 testing on azure US and australia

ignore this

```

sudo yum install tmux dstat -y

time mirrormgr --deployment-data SASViyaV4_9CFHCQ_certs.zip mirror registry \
    --destination notused:5001 \
    --latest \
    --path /mnt/resource/sas_repo \
    --log-file ./run1.log

default worker: 16

    display: 321 MiB/s
    dstat: up to 600 M
    it took 9 minutes
    there was 51 GB in the folder


time mirrormgr --deployment-data SASViyaV4_9CFHCQ_certs.zip mirror registry \
    --destination notused:5001 \
    --latest \
    --path /mnt/resource/sas_repo \
    --log-file ./run1.log \
    --workers 32

    display: 500 MiB/s
    dstat: up to 1100 M
    it took 5.5 minutes
    there was 49 GB in the folder


latency: 0.03 s = 30 ms
[cloud-user@mirror-us ~]$ curl ses.sas.download -s -o /dev/null -w  "%{time_starttransfer}\n"
0.234491

wget https://github.com/yuya-takeyama/ntimes/releases/download/v0.1.0/linux_amd64_0.1.0.zip
unzip linux_amd64_0.1.0.zip
wget https://github.com/yuya-takeyama/percentile/releases/download/v0.0.1/linux_amd64_0.0.1.zip
unzip linux_amd64_0.0.1.zip
./ntimes 100 -- curl ses.sas.download -s -o /dev/null -w  "%{time_starttransfer}\n" | ./percentile


[cloud-user@mirror-aus ~]$ mirrormgr --version
mirrormgr:
 version     : 0.25.0
 build date  : 2020-07-26
 git hash    : bcaad82
 go version  : go1.14.2
 go compiler : gc
 platform    : linux/amd64
[cloud-user@mirror-aus ~]$

Australia


sudo mv mirrormgr_1 /usr/local/bin/mirrormgr
sudo chmod 755 /usr/local/bin/mirrormgr
sudo chown cloud-user:cloud-user /usr/local/bin/mirrormgr

sudo mkdir /mnt/resource/sas_repo
sudo chmod 755  /mnt/resource/sas_repo
sudo chown cloud-user:cloud-user  /mnt/resource/sas_repo


time mirrormgr --deployment-data SASViyaV4_9CFHCQ_certs.zip mirror registry \
    --destination notused:5001 \
    --latest \
    --path /mnt/resource/sas_repo \
    --log-file ./run1.log

    display: 65 MiB/s
    dstat: up to 230 M
    it took 20.5 minutes
    there was 51 GB in the folder

rm -rf /mnt/resource/sas_repo/*
time mirrormgr --deployment-data SASViyaV4_9CFHCQ_certs.zip mirror registry \
    --destination notused:5001 \
    --latest \
    --path /mnt/resource/sas_repo \
    --log-file ./run1.log \
    --workers 32


    display: 300 MiB/s
    dstat: up to 230 M
    it took 7 minutes
    there was 51 GB in the folder

slows down at the end.

```
-->

## Navigation

<!-- startnav -->
* [01 Introduction / 01 031 Booking a Lab Environment for the Workshop](/01_Introduction/01_031_Booking_a_Lab_Environment_for_the_Workshop.md)
* [01 Introduction / 01 032 Assess Readiness of Lab Environment](/01_Introduction/01_032_Assess_Readiness_of_Lab_Environment.md)
* [01 Introduction / 01 033 CheatCodes](/01_Introduction/01_033_CheatCodes.md)
* [02 Kubernetes and Containers Fundamentals / 02 131 Learning about Namespaces](/02_Kubernetes_and_Containers_Fundamentals/02_131_Learning_about_Namespaces.md)
* [03 Viya 4 Software Specifics / 03 011 Looking at a Viya 4 environment with Visual Tools DEMO](/03_Viya_4_Software_Specifics/03_011_Looking_at_a_Viya_4_environment_with_Visual_Tools_DEMO.md)
* [03 Viya 4 Software Specifics / 03 051 Create your own Viya order](/03_Viya_4_Software_Specifics/03_051_Create_your_own_Viya_order.md)
* [03 Viya 4 Software Specifics / 03 056 Getting the order with the CLI](/03_Viya_4_Software_Specifics/03_056_Getting_the_order_with_the_CLI.md)
* [04 Pre Requisites / 04 081 Pre Requisites automation with Viya4-ARK](/04_Pre-Requisites/04_081_Pre-Requisites_automation_with_Viya4-ARK.md)
* [05 Deployment tools / 05 121 Setup a Windows Client Machine](/05_Deployment_tools/05_121_Setup_a_Windows_Client_Machine.md)
* [06 Deployment Steps / 06 031 Deploying a simple environment](/06_Deployment_Steps/06_031_Deploying_a_simple_environment.md)
* [06 Deployment Steps / 06 051 Deploying Viya with Authentication](/06_Deployment_Steps/06_051_Deploying_Viya_with_Authentication.md)
* [06 Deployment Steps / 06 061 Deploying in a second namespace](/06_Deployment_Steps/06_061_Deploying_in_a_second_namespace.md)
* [06 Deployment Steps / 06 071 Removing Viya deployments](/06_Deployment_Steps/06_071_Removing_Viya_deployments.md)
* [06 Deployment Steps / 06 081 Deploying a programing only environment](/06_Deployment_Steps/06_081_Deploying_a_programing-only_environment.md)
* [06 Deployment Steps / 06 091 Deployment Operator setup](/06_Deployment_Steps/06_091_Deployment_Operator_setup.md)
* [06 Deployment Steps / 06 093 Using the DO with a Git Repository](/06_Deployment_Steps/06_093_Using_the_DO_with_a_Git_Repository.md)
* [06 Deployment Steps / 06 095 Using an inline configuration](/06_Deployment_Steps/06_095_Using_an_inline_configuration.md)
* [06 Deployment Steps / 06 097 Using the Orchestration Tool](/06_Deployment_Steps/06_097_Using_the_Orchestration_Tool.md)
* [06 Deployment Steps / 06 101 Create Viya Deployment Roles](/06_Deployment_Steps/06_101_Create_Viya_Deployment_Roles.md)
* [07 Deployment Customizations / 07 021 Configuring SASWORK](/07_Deployment_Customizations/07_021_Configuring_SASWORK.md)
* [07 Deployment Customizations / 07 051 Adding a local registry to k8s](/07_Deployment_Customizations/07_051_Adding_a_local_registry_to_k8s.md)
* [07 Deployment Customizations / 07 052 Using mirror manager to populate the local registry](/07_Deployment_Customizations/07_052_Using_mirror_manager_to_populate_the_local_registry.md)**<-- you are here**
* [07 Deployment Customizations / 07 053 Deploy from local registry](/07_Deployment_Customizations/07_053_Deploy_from_local_registry.md)
* [07 Deployment Customizations / 07 091 Configure SAS ACCESS Engine](/07_Deployment_Customizations/07_091_Configure_SAS_ACCESS_Engine.md)
* [07 Deployment Customizations / 07 101 Configure SAS ACCESS TO HADOOP](/07_Deployment_Customizations/07_101_Configure_SAS_ACCESS_TO_HADOOP.md)
* [07 Deployment Customizations / 07 102 Parallel loading with EP for Hadoop](/07_Deployment_Customizations/07_102_Parallel_loading_with_EP_for_Hadoop.md)
* [09 Validation / 09 011 Validate the Viya deployment](/09_Validation/09_011_Validate_the_Viya_deployment.md)
* [09 Validation / 09 021 SAS Viya deployment reports](/09_Validation/09_021_SAS_Viya_deployment_reports.md)
* [11 Azure AKS Deployment / 11 000 Navigating the AKS Hands on Deployment Options](/11_Azure_AKS_Deployment/11_000_Navigating_the_AKS_Hands-on_Deployment_Options.md)
* [11 Azure AKS Deployment / 11 999 Fast track with cheatcodes](/11_Azure_AKS_Deployment/11_999_Fast_track_with_cheatcodes.md)
* [11 Azure AKS Deployment/Fully Automated / 11 500 Full Automation of AKS Deployment](/11_Azure_AKS_Deployment/Fully_Automated/11_500_Full_Automation_of_AKS_Deployment.md)
* [11 Azure AKS Deployment/Fully Automated / 11 590 Cleanup](/11_Azure_AKS_Deployment/Fully_Automated/11_590_Cleanup.md)
* [11 Azure AKS Deployment/Standard / 11 100 Creating an AKS Cluster](/11_Azure_AKS_Deployment/Standard/11_100_Creating_an_AKS_Cluster.md)
* [11 Azure AKS Deployment/Standard / 11 110 Performing the prerequisites](/11_Azure_AKS_Deployment/Standard/11_110_Performing_the_prerequisites.md)
* [11 Azure AKS Deployment/Standard/Cleanup / 11 400 Cleanup](/11_Azure_AKS_Deployment/Standard/Cleanup/11_400_Cleanup.md)
* [11 Azure AKS Deployment/Standard/Manual / 11 200 Deploying Viya 4 on AKS](/11_Azure_AKS_Deployment/Standard/Manual/11_200_Deploying_Viya_4_on_AKS.md)
* [11 Azure AKS Deployment/Standard/Manual / 11 210 Deploy a second namespace in AKS](/11_Azure_AKS_Deployment/Standard/Manual/11_210_Deploy_a_second_namespace_in_AKS.md)
* [11 Azure AKS Deployment/Standard/Manual / 11 220 CAS Customizations](/11_Azure_AKS_Deployment/Standard/Manual/11_220_CAS_Customizations.md)
* [11 Azure AKS Deployment/Standard/Manual / 11 230 Install monitoring and logging](/11_Azure_AKS_Deployment/Standard/Manual/11_230_Install_monitoring_and_logging.md)
* [12 Amazon EKS Deployment / 12 010 Access Environments](/12_Amazon_EKS_Deployment/12_010_Access_Environments.md)
* [12 Amazon EKS Deployment / 12 020 Provision Resources](/12_Amazon_EKS_Deployment/12_020_Provision_Resources.md)
* [12 Amazon EKS Deployment / 12 030 Deploy SAS Viya](/12_Amazon_EKS_Deployment/12_030_Deploy_SAS_Viya.md)
* [13 Google GKE Deployment / 13 011 Creating a GKE Cluster](/13_Google_GKE_Deployment/13_011_Creating_a_GKE_Cluster.md)
* [13 Google GKE Deployment / 13 021 Performing Prereqs in GKE](/13_Google_GKE_Deployment/13_021_Performing_Prereqs_in_GKE.md)
* [13 Google GKE Deployment / 13 031 Deploying Viya 4 on GKE](/13_Google_GKE_Deployment/13_031_Deploying_Viya_4_on_GKE.md)
* [13 Google GKE Deployment / 13 041 Full Automation of GKE Deployment](/13_Google_GKE_Deployment/13_041_Full_Automation_of_GKE_Deployment.md)
* [13 Google GKE Deployment / 13 099 Fast track with cheatcodes](/13_Google_GKE_Deployment/13_099_Fast_track_with_cheatcodes.md)
<!-- endnav -->
