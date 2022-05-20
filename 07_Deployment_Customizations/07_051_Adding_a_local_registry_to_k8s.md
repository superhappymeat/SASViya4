![Global Enablement & Learning](https://gelgitlab.race.sas.com/GEL/utilities/writing-content-in-markdown/-/raw/master/img/gel_banner_logo_tech-partners.jpg)

# Creating a local container registry

* [Installing Harbor](#installing-harbor)
  * [Update the URLs for Harbor](#update-the-urls-for-harbor)
* [Logging in and creating a new repository](#logging-in-and-creating-a-new-repository)
* [code to auto-create this](#code-to-auto-create-this)
* [Navigation](#navigation)

## Installing Harbor

1. We have written a script that will automate the creation of your own instance of Harbor:

    ```bash
    bash  /opt/gellow_code/scripts/loop/viya4/GEL.0400.Optional.Harbor.sh harborV1

    ```

<!--
1. First you should create a namespace to hold Harbor

    ```bash
    kubectl create ns harbor

    ```

1. These commands will deploy Harbor using Helm

    ```bash
    HARBORADM=admin
    HARBORPASS=lnxsas

    # Override harbor manifest to pull harbor images from gelharbor

    tee /tmp/harbor.values.yaml > /dev/null <<EOF
    ---
    expose:
      type: ingress
      tls:
        enabled: true
      ingress:
        hosts:
          core: harbor.$(hostname -f)
          notary: notary.$(hostname -f)

    persistence:
      enabled: true
      persistentVolumeClaim:
        registry:
          size: 55Gi


    externalURL: https://harbor.$(hostname -f)/

    harborAdminPassword: ${HARBORPASS}

    ## overriding default images to use GELHARBOR

    nginx:
      image:
        repository: gelharbor.race.sas.com/dockerhubstaticcache/goharbor/nginx-photon
        tag: v2.1.3
    portal:
      image:
        repository: gelharbor.race.sas.com/dockerhubstaticcache/goharbor/harbor-portal
        tag: v2.1.3
    core:
      image:
        repository: gelharbor.race.sas.com/dockerhubstaticcache/goharbor/harbor-core
        tag: v2.1.3
    jobservice:
      image:
        repository: gelharbor.race.sas.com/dockerhubstaticcache/goharbor/harbor-jobservice
        tag: v2.1.3
    registry:
      registry:
        image:
          repository: gelharbor.race.sas.com/dockerhubstaticcache/goharbor/registry-photon
          tag: v2.1.3
      controller:
        image:
          repository: gelharbor.race.sas.com/dockerhubstaticcache/goharbor/harbor-registryctl
          tag: v2.1.3
    chartmuseum:
      image:
        repository: gelharbor.race.sas.com/dockerhubstaticcache/goharbor/chartmuseum-photon
        tag: v2.1.3
    clair:
      enabled: false
      clair:
        image:
          repository: gelharbor.race.sas.com/dockerhubstaticcache/goharbor/clair-photon
          tag: v2.1.3
      adapter:
        image:
          repository: gelharbor.race.sas.com/dockerhubstaticcache/goharbor/clair-adapter-photon
          tag: v2.1.3
    trivy:
      image:
        repository: gelharbor.race.sas.com/dockerhubstaticcache/goharbor/trivy-adapter-photon
        tag: v2.1.3
    notary:
      server:
        image:
          repository: gelharbor.race.sas.com/dockerhubstaticcache/goharbor/notary-server-photon
          tag: v2.1.3
      signer:
        serviceAccountName: ""
        image:
          repository: gelharbor.race.sas.com/dockerhubstaticcache/goharbor/notary-signer-photon
          tag: v2.1.3
    database:
      internal:
        image:
          repository: gelharbor.race.sas.com/dockerhubstaticcache/goharbor/harbor-db
          tag: v2.1.3
    redis:
      internal:
        image:
          repository: gelharbor.race.sas.com/dockerhubstaticcache/goharbor/redis-photon
          tag: v2.1.3
    EOF

    kubectl create ns harbor
    helm repo add harbor https://helm.goharbor.io
    helm install my-harbor harbor/harbor \
        --namespace harbor \
        --version v1.5.3 \
        --values /tmp/harbor.values.yaml

    ```

1. wait for all pods in namespace to be ready:

    ```bash
    waitforpods () {
        PODS_NOT_READY=99
        while [ "${PODS_NOT_READY}" != "0" ]
        do
            PODS_NOT_READY=$(kubectl get pods -n $1 --no-headers | grep -v Completed | grep -E -v '1/1|2/2' | wc -l)
            printf "\n\n\nWaiting for these ${PODS_NOT_READY} pods to be Running: \n"
            kubectl get pods -n $1 --no-headers | grep -v Completed | grep -E -v '1/1|2/2'
            sleep 5
        done
        printf "All pods in namespace $1 seem to be ready \n\n\n\n"
    }

    waitforpods harbor
    ```
 -->

1. Now, test that we can use it:

    ```bash
    docker login harbor.$(hostname -f):443 -u admin -p lnxsas

    docker pull centos:7
    docker tag centos:7 harbor.$(hostname -f):443/library/centos:7
    docker push  harbor.$(hostname -f):443/library/centos:7
    ```

### Update the URLs for Harbor

1. Adding the harbor URLs to the `~/urls.md/ file:

    ```bash
    printf "\n* [Local Harbor Registry URL (HTTPS)](https://harbor.$(hostname -f)/ ) (u=admin,p=lnxsas)\n\n" | tee -a /home/cloud-user/urls.md

    ```

1. Click on that url and log into Harbor, as user `admin` with password `lnxsas`.

1. Confirm that you can see the `centos:7` image in the `library` registry.

## Logging in and creating a new repository

In order to get familiar with Harbor, you might want to do the following steps "manually" first. (after that, some automated code will re-do the same thing for you again)

Using your web browser, log into Harbor and:

* create a project called **viya_manual**
* create a robot account called **viya_manual**

* the real account and credentials will be done automatically in the next step.

## code to auto-create this

for a scripted way of doing the same, check out those instructions:

<https://gitlab.sas.com/adbull/documentation/-/blob/master/mirror_harbor.md>

so:

```bash
# credits to Adam Bullock for this elegant piece of work

export PROJECTNAME=viya
HARBORADM=admin
HARBORPASS=lnxsas
export HARBOR_ING=$(kubectl -n harbor get ing  my-harbor-harbor-ingress \
                -o custom-columns='host:spec.rules[*].host' --no-headers)
ROBOUSER=viya

curl -k -X POST "https://$HARBOR_ING/api/v2.0/projects" \
    -u $HARBORADM:$HARBORPASS \
    -H 'Content-Type: application/json' \
    --data '{"project_name": "'"$PROJECTNAME"'"}'

PROJECT_ID=$(curl -k -s -X GET "https://$HARBOR_ING/api/v2.0/projects?name=$PROJECTNAME" \
    -H "accept: application/json" -u $HARBORADM:$HARBORPASS | \
    jq '.[] |  select(.name=="'"$PROJECTNAME"'") | .project_id')

curl -k -s -X POST "https://$HARBOR_ING/api/v2.0/projects/$PROJECT_ID/robots" \
    -u $HARBORADM:$HARBORPASS \
    -H 'Content-Type: application/json' \
    --data '{
    "access": [
        {
        "action": "push",
        "resource": "/project/'$PROJECT_ID'/repository"
        }
    ],
    "name": "'$ROBOUSER'",
    "description": "Used for viya"
    }' -k -o ~/exportRobot.json

```

The created file (`~/exportRobot.json`) contains the credentials that allow the `robot$viya` user to access the newly created **viya** project inside harbor.

Open the Harbor web interface to confirm the project exists.

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
* [07 Deployment Customizations / 07 051 Adding a local registry to k8s](/07_Deployment_Customizations/07_051_Adding_a_local_registry_to_k8s.md)**<-- you are here**
* [07 Deployment Customizations / 07 052 Using mirror manager to populate the local registry](/07_Deployment_Customizations/07_052_Using_mirror_manager_to_populate_the_local_registry.md)
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
