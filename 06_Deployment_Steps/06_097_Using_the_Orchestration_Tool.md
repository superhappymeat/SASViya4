![Global Enablement & Learning](https://gelgitlab.race.sas.com/GEL/utilities/writing-content-in-markdown/-/raw/master/img/gel_banner_logo_tech-partners.jpg)

# Using the Orchestration Tool to create the SASDeployment Custom Resource

* [Introduction](#introduction)
* [Environment setup - getting the Orchestration Tool](#environment-setup-getting-the-orchestration-tool)
  * [Pull the orchestration tool image from SAS](#pull-the-orchestration-tool-image-from-sas)
* [But first, some rules...](#but-first-some-rules)
* [Create an inline Custom Resource](#create-an-inline-custom-resource)
  * [Inspect the CR file](#inspect-the-cr-file)
* [Create a Custom Resource using Git a project](#create-a-custom-resource-using-git-a-project)
  * [Inspect the new CR file](#inspect-the-new-cr-file)
* [Navigation](#navigation)

## Introduction

Using the Orchestration Tool... the easy path! :-)

Now that you have had the experience of editing YAML files by hand, we will now look at using the Orchestration Tool for generate the custom resource.

For this set of exercises you will use the tool to generate an inline CR file, then you will use the tool to generate a CR that is using the Git Repository.

To do this you need to first pull down the Orchestration Tool.

***This exercise assumes that you have completed the initial setup steps and the Discovery environment (using Git) exercises.***

## Environment setup - getting the Orchestration Tool

The SASDeployment custom resource can be created and maintained using the orchestration tool. The instructions to deploy the orchestration tool are in the “Prerequisites” section of the README file at $deploy/sas-bases/examples/kubernetes-tools/README.md (for Markdown format) or $deploy/sas-bases/docs/using_kubernetes_tools_from_the_sas-orchestration_image.htm (for HTML format).

### Pull the orchestration tool image from SAS

Use the following steps.

1. Log in to the SAS Registry (cr.sas.com), and retrieve the `sas-orchestration` image.

    ```bash
    # Set environment variable
    DEPOP_VER=stable-2020.1.5

    cd ~/project/operator-setup/${DEPOP_VER}
    cat sas-bases/examples/kubernetes-tools/password.txt | docker login cr.sas.com --username '9CFHCQ' --password-stdin
    docker pull cr.sas.com/viya-4-x64_oci_linux_2-docker/sas-orchestration:1.37.1-20210212.1613150172023
    ```

1. Logout of cr.sas.com

    ```bash
    docker logout cr.sas.com
    ```

1. Replace the image tag

    Replace 'cr.sas.com/viya-4-x64_oci_linux_2-docker/sas-orchestration:1.37.1-20210212.1613150172023' with a local tag for ease of use. We will use 'sas-orch'.

    ```bash
    docker tag cr.sas.com/viya-4-x64_oci_linux_2-docker/sas-orchestration:1.37.1-20210212.1613150172023 sas-orch
    ```

    To confirm the change the following command can be used `docker image list | grep sas-orch`.

You are now all set to start using the orchestration tool.

## But first, some rules...

From testing the following should be noted:

* Keep the license separate from the user-content files.
* Don't output the CR yaml to the user-content folder.
* The user content can be in the local files system, web server or git.

## Create an inline Custom Resource

Use the following steps to create the inline CR.

1. Create a working directory.

    ```bash
    # Create the working directory
    cd ~/project/operator-driven/inline-projects
    mkdir -p ~/project/operator-driven/inline-projects/cr-working
    ```

1. Get the certificates and license files.

    For this you will copy the files from the /operator-setup folder to the working folder.

    ```bash
    cp ~/project/operator-setup/${DEPOP_VER}/*.zip ~/project/operator-driven/inline-projects/cr-working/SASViyaV4_certs.zip
    cp ~/project/operator-setup/${DEPOP_VER}/*.jwt ~/project/operator-driven/inline-projects/cr-working/SASViyaV4_license.jwt
    ```

1. Prep the Viya configuration, the 'user-content'.

    For this we will use the Discovery setup as the configuration files. To do this you will copy the files from the Discovery Git project folder.

    ```bash
    # Create the folder the SAS environment configuration files
    mkdir -p ~/project/operator-driven/inline-projects/discovery

    # Copy the Discovery kustomization.yaml file
    cp ~/project/operator-driven/git-projects/discovery/kustomization.yaml ~/project/operator-driven/inline-projects/discovery/

    # Copy the site-config files
    cp -Rf ~/project/operator-driven/git-projects/discovery/site-config ~/project/operator-driven/inline-projects/discovery/
    ```

1. Create the Custom Resource file.

    ```bash
    cd ~/project/operator-driven/inline-projects/
    docker run --rm \
    -v ${PWD}:/cr-working \
    -w /cr-working \
    --user $(id -u):$(id -g) \
    sas-orch \
    create sas-deployment-cr \
    --deployment-data ./cr-working/SASViyaV4_certs.zip \
    --license ./cr-working/SASViyaV4_license.jwt \
    --user-content ./discovery \
    --cadence-name stable \
    --cadence-version 2020.1.5 \
    > discovery-sasdeployment.yaml
    ```

### Inspect the CR file

Now that the custom resource has been created you can inspect what as been created.

```sh
vi  ~/project/operator-driven/inline-projects/discovery-sasdeployment.yaml
```

## Create a Custom Resource using Git a project

That was nice, but it would be better if we had all the Viya configuration file in a Git project, to put them under source control.

Remember each Viya environment (configuration) should be in its own Git project. For this exercise we will use the Discovery Git project that you created earlier.  See [here](/06_Deployment_Steps/06_093_Using_the_DO_with_a_Git_Repository.md), using the operator with a Git Repository.

1. Copy the required assets to the Git project.

    As the tool is looking for the zip file you need to copy that to the Git project folder.

    ```bash
    cp ~/project/operator-setup/${DEPOP_VER}/*.zip ~/project/operator-driven/git-projects/discovery/secrets/SASViyaV4_certs.zip
    ```

1. Push the updates to the Git project.

    Now commit the files to the Discovery project.

    ```bash
    cd ~/project/operator-driven/git-projects/discovery
    # Now push the file to your Git project
    git add .
    git commit -m "Commit Discovery config"
    # Get host name and set URL
    HOST_SUFFIX=$(hostname -f)
    DISCORY_URL=http://gitlab.devops.${HOST_SUFFIX}/cloud-user/discovery.git

    # PUSH the files
    git push $DISCOVERY_URL
    ```

1. Create the Custom Resource using a Git project and write the CR to the Git project folder.

    ```bash
    cd ~/project/operator-driven/inline-projects/

    INGRESS_SUFFIX=$(hostname -f)
    echo $INGRESS_SUFFIX

    docker run --rm \
    -v ${PWD}:/cr-working \
    -w /cr-working \
    --user $(id -u):$(id -g) \
    sas-orch \
    create sas-deployment-cr \
    --deployment-data http://gitlab.devops.${INGRESS_SUFFIX}/cloud-user/discovery/-/raw/master/secrets/SASViyaV4_certs.zip \
    --license  http://gitlab.devops.${INGRESS_SUFFIX}/cloud-user/discovery/-/raw/master/secrets/license/SASViyaV4_license.jwt \
    --user-content git::http://gitlab.devops.${INGRESS_SUFFIX}/cloud-user/discovery.git \
    --cadence-name stable \
    --cadence-version 2020.1.5 \
    > ~/project/operator-driven/git-projects/discovery/discovery2-sasdeployment.yaml
    ```

### Inspect the new CR file

If you inspect the new CR file (`discovery2-sasdeployment.yaml`) you will notice that the secrets have been created inline while the license file and Viya configuration files are being read directly from the Git project.

```sh
cd ~/project/operator-driven/git-projects/discovery/
vi discovery2-sasdeployment.yaml
```

To see the differences between the two files use the following command.

```sh
# Compare the two CR files
icdiff ~/project/operator-driven/inline-projects/discovery-sasdeployment.yaml \
 ~/project/operator-driven/git-projects/discovery/discovery2-sasdeployment.yaml
```

If you have the time and energy to test the CR that was generated, you should clean-up the old discovery deployment before applying the new CR.

```sh
# Clean up Discovery environment
kubectl delete ns discovery
kubectl create ns discovery

# Deploy GELLDAP again
NS=discovery
HOST_SUFFIX=$(hostname -f)
GITLAB_URL=http://gitlab.devops.${HOST_SUFFIX}
kubectl apply -f ${GITLAB_URL}/cloud-user/gelldap2/-/raw/master/gelldap-build.yaml -n ${NS}

# Apply the CR to deploy a new discovery environment
cd ~/project/operator-driven/git-projects/discovery
kubectl apply -f discovery2-sasdeployment.yaml -n discovery
```

As you can see, using the Orchestration Tool is definitely easier than manually creating and editing the custom resource YAML file.

Remember you still need to create the Viya kustomizations to configure the SAS Viya environment. In this case we reused the Discovery configuration that you created earlier.

This concludes the deployment operator exercises.

---

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
* [06 Deployment Steps / 06 097 Using the Orchestration Tool](/06_Deployment_Steps/06_097_Using_the_Orchestration_Tool.md)**<-- you are here**
* [06 Deployment Steps / 06 101 Create Viya Deployment Roles](/06_Deployment_Steps/06_101_Create_Viya_Deployment_Roles.md)
* [07 Deployment Customizations / 07 021 Configuring SASWORK](/07_Deployment_Customizations/07_021_Configuring_SASWORK.md)
* [07 Deployment Customizations / 07 051 Adding a local registry to k8s](/07_Deployment_Customizations/07_051_Adding_a_local_registry_to_k8s.md)
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
