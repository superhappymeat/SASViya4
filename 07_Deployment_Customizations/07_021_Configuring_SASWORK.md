![Global Enablement & Learning](https://gelgitlab.race.sas.com/GEL/utilities/writing-content-in-markdown/-/raw/master/img/gel_banner_logo_tech-partners.jpg)

# Configuring SASWORK

* [Working location](#working-location)
* [Kick off a vanilla "gelenv" deployment](#kick-off-a-vanilla-gelenv-deployment)
* [Default: emptyDir](#default-emptydir)
* [Reconfiguring SASWORK through an extra hostPath VolumeMount](#reconfiguring-saswork-through-an-extra-hostpath-volumemount)
  * [creating alternative locations](#creating-alternative-locations)
* [Creating a copy of "gelenv"](#creating-a-copy-of-gelenv)
  * [referring to another kustomization](#referring-to-another-kustomization)
  * [creating a custom saswork yaml file](#creating-a-custom-saswork-yaml-file)
* [Validating that the hostPath mount is functioning](#validating-that-the-hostpath-mount-is-functioning)
  * [Generic steps](#generic-steps)
  * [Detailed steps](#detailed-steps)
* [Navigation](#navigation)

In this exercise, we will walk through the steps required to setup SASWORK in an alternative location

## Working location

1. for this exercise, we will work in this folder:

    ```bash
    mkdir -p ~/project/deploy/gelenv-saswork

    ```

## Kick off a vanilla "gelenv" deployment

1. We are going to kick off a vanilla Viya 4 env in a namespace called "gelenv":

    ```bash

    CADENCE_NAME='stable'
    CADENCE_VERSION='2020.1.5'
    ORDER_NICKNAME='full'

    ansible-playbook /opt/gellow_code/scripts/loop/viya4/gelenv/gelenv.yaml \
        --tags generate \
        --tags deploy \
        -e "GELENV_CADENCE_NAME=${CADENCE_NAME} \
            GELENV_CADENCE_VERSION=${CADENCE_VERSION} \
            GELENV_ORDER_NICKNAME=${ORDER_NICKNAME}    \
            GELENV_NS=gelenv    \
            GELENV_ROOT=/home/cloud-user/project/deploy/gelenv    \
            GELENV_INGRESS_PREFIX=gelenv    \
            GELENV_HA=false"

    ```

1. That command should take up to 3 minutes

1. This will generate manifests in the following directory:

    * `~/project/deploy/gelenv`

1. And it will also apply them, therefore starting up the environment.

1. If you want, you can re-apply the manifest again:

    ```bash
    kubectl -n gelenv apply -f ~/project/deploy/gelenv/site.yaml

    ```

1. There is no need to wait for the environment to be fully up. We have other things to do in the meantime.

## Default: emptyDir

* investigate where SASWORK is currently going
* Figure out if it's the place where you want it to be

## Reconfiguring SASWORK through an extra hostPath VolumeMount

### creating alternative locations

The servers provided in the RACE collection have a single disk, so we will merely create a new folder in the root partition to simulate a mountpoint that would lead to a different disk

1. To create the new folders:

    ```bash
    ansible sasnode* -m file -b -a "path=/sastmp mode=0755 state=directory"
    ansible sasnode* -m file -b -a "path=/sastmp/saswork mode=0777 state=directory"

    ```

## Creating a copy of "gelenv"

### referring to another kustomization

Rather than copying the entire content of gelenv, we will create a kustomization.yaml that simply differ slightly from it.

1. we start with a kustomization.yaml that refers to the other directory:

    ```bash
    cat > ~/project/deploy/gelenv-saswork/kustomization.yaml <<-EOF
    ---
    resources:
      - ../gelenv

    EOF
    ```

1. Once that is done, we can now easily create an identical manifest and apply it. This will not (yet) change anything:

    ```bash
    cd ~/project/deploy/gelenv-saswork/
    kustomize build -o site.yaml

    ## confirm there are no differences:
    diff site.yaml ../gelenv/site.yaml

    kubectl -n gelenv apply -f site.yaml
    ```

### creating a custom saswork yaml file

1. Run the command below to generate the PatchTransformer file content.

    ```bash
    mkdir  ~/project/deploy/gelenv-saswork/site-config/

    tee ~/project/deploy/gelenv-saswork/site-config/custom-saswork.yaml > /dev/null <<EOF
    # # this defines the volume and volumemount for SASWORK
    # # it uses hostPath to easily access any folder on the node
    ---
    apiVersion: builtin
    kind: PatchTransformer
    metadata:
      name: custom-saswork-location
    patch: |-
      - op: add
        path: /template/spec/volumes/-
        value:
          name: saswork
          # # HostPath, is the path on the host, outside the pod
          hostPath:
            path: /sastmp/saswork
      - op: add
        path: /template/spec/containers/0/volumeMounts/-
        value:
          name: saswork
          # # MountPath is what it will be mounted as, inside the pod
          mountPath: /opt/sas/viya/config/var/tmp/compsrv/default
    target:
      version: v1
      # # For Compute sessions, they are defined by a PodTemplate
      kind: PodTemplate
      # # But not all PodTemplates, only those related to SPRE sessions
      labelSelector: "sas.com/template-intent=sas-launcher"

    EOF


    ```

1. and now, we re-create the kustomization file to refer to our new transformer:

    ```bash
    tee ~/project/deploy/gelenv-saswork/kustomization.yaml > /dev/null <<EOF
    ---
    resources:
      - ../gelenv
    transformers:
      - site-config/custom-saswork.yaml

    EOF

    ```

1. So let's re-build now

    ```bash
    cd ~/project/deploy/gelenv-saswork/
    mv site.yaml site.yaml.before_saswork

    kustomize build -o site.yaml
    ```

1. Review the difference to confirm your changes are being taken.

    ```sh
    icdiff site.yaml.before_saswork site.yaml

    ```

1. and apply

    ```bash
    kubectl -n gelenv apply -f site.yaml

    ```

1. This will NOT restart any pods. It only alters the PodTemplate definition for your Compute sessions.

## Validating that the hostPath mount is functioning

### Generic steps

* Log into Studio
* Wait for Compute session to be ready
* Create a recognizable Dataset in the Work library
* Determine on which node that pod is running
* Log onto the node itself, and see if you can see that recognizable dataset

Note that all this may or may not be do-able in a customer's cluster. You may need the K8S admin to do parts of this for you.

### Detailed steps

1. Connect to SAS Studio
1. Log in as a regular user
   * U: `alex`
   * P: `lnxsas`
1. Once in Studio, run the following code:

    ```sas
    data work.alex;
    set sashelp.cars;
    do i=1 to 100;
        output;
    end;
    run;

    ```

1. Leave SAS Studio open, and log in to sasnode01 as cloud-user
1. Once there, determine where your pod is running:

    ```bash
    kubectl -n gelenv get pods -l launcher.sas.com/username=Alex -o wide

    ```

1. You should see:

    ```log
    NAME                                                      READY   STATUS    RESTARTS   AGE    IP           NODE        NOMINATED NODE   READINESS GATES
    sas-launcher-b8105be3-b036-4b76-9f51-9d3e679bff16-z5q9b   1/1     Running   0          5m2s   10.42.1.20   intnode01   <none>           <none>
    ```

1. so let's grab the pod name and the pods's node:

    ```bash

    PODNAME=$(kubectl -n gelenv get pods -l launcher.sas.com/username=Alex \
             -o=custom-columns=PODNAME:.metadata.name --no-headers)
    NODENAME=$(kubectl -n gelenv get pods -l launcher.sas.com/username=Alex \
            -o=custom-columns=NODENAME:.spec.nodeName --no-headers)

    printf "it seems that pod: \n   ${PODNAME} \nis running on node: \n    ${NODENAME} \n\n"

    ```

1. Now, let's look at the paths **inside the pod**:

    ```bash
    kubectl -n gelenv exec -it ${PODNAME} -- bash -c "ls -alR /opt/sas/viya/config/var/tmp/compsrv/default"

    ```

1. Output:

    <details><summary>Click here to see the expected output:</summary>

    ```log
    [cloud-user@rext03-0159 gelenv-saswork]$ kubectl -n gelenv exec -it ${PODNAME} -- bash -c "ls -alR /opt/sas/viya/config/var/tmp/compsrv/default"
    Defaulted container "sas-programming-environment" out of: sas-programming-environment, sas-certframe (init), sas-config-init (init)
    /opt/sas/viya/config/var/tmp/compsrv/default:
    total 12
    drwxrwxrwx 3 root root 4096 Apr 27 13:35 .
    drwxrwsrwx 3 sas  2003 4096 Apr 27 13:35 ..
    drwxr-xr-x 3 4003 2003 4096 Apr 27 13:35 ab7a89c9-0861-4883-92cb-f89f63b6ae21

    /opt/sas/viya/config/var/tmp/compsrv/default/ab7a89c9-0861-4883-92cb-f89f63b6ae21:
    total 12
    drwxr-xr-x 3 4003 2003 4096 Apr 27 13:35 .
    drwxrwxrwx 3 root root 4096 Apr 27 13:35 ..
    drwx------ 2 4003 2003 4096 Apr 27 13:37 SAS_work52E1000000AC_sas-launcher-d4655770-dd8d-4079-8381-1d2269ef4c57-flw74

    /opt/sas/viya/config/var/tmp/compsrv/default/ab7a89c9-0861-4883-92cb-f89f63b6ae21/SAS_work52E1000000AC_sas-launcher-d4655770-dd8d-4079-8381-1d2269ef4c57-flw74:
    total 7272
    drwx------ 2 4003 2003    4096 Apr 27 13:37  .
    drwxr-xr-x 3 4003 2003    4096 Apr 27 13:35  ..
    -rw-r--r-- 1 4003 2003 6946816 Apr 27 13:37  alex.sas7bdat
    -rw-r--r-- 1 4003 2003   46056 Apr 27 13:37 '#LN00015'
    -rw-r--r-- 1 4003 2003       0 Apr 27 13:37 '#LN00016'
    -rw-r--r-- 1 4003 2003   12288 Apr 27 13:35  profile.sas7bcat
    -rw-r--r-- 1 4003 2003   32768 Apr 27 13:35  regstry.sas7bitm
    -rw-r--r-- 1 4003 2003   12288 Apr 27 13:37  sasgopt.sas7bcat
    -rw-r--r-- 1 4003 2003       0 Apr 27 13:35  sas.lck
    -rw-r--r-- 1 4003 2003   20480 Apr 27 13:35  sasmac1.sas7bcat
    -rw-r--r-- 1 4003 2003   20480 Apr 27 13:35  sasmac2.sas7bcat
    -rw-r--r-- 1 4003 2003   20480 Apr 27 13:37  sasmac3.sas7bcat
    -rw-r--r-- 1 4003 2003   20480 Apr 27 13:35  sasmac4.sas7bcat
    -rw-r--r-- 1 4003 2003   20480 Apr 27 13:35  sasmac5.sas7bcat
    -rw-r--r-- 1 4003 2003   20480 Apr 27 13:35  sasmac6.sas7bcat
    -rw-r--r-- 1 4003 2003   20480 Apr 27 13:35  sasmac7.sas7bcat
    -rw-r--r-- 1 4003 2003   20480 Apr 27 13:35  sasmac8.sas7bcat
    -rw-r--r-- 1 4003 2003   20480 Apr 27 13:35  sasmac9.sas7bcat
    -rw-r--r-- 1 4003 2003  143360 Apr 27 13:37  sasmacr.sas7bcat
    -rw-r--r-- 1 4003 2003  131072 Apr 27 13:37  sastmp-000000004.sas7butl
    -rw-r--r-- 1 4003 2003  103424 Apr 27 13:37  sastmp-000000010.sas7bitm
    ```

    </details>

1. Now, let's look at the paths **on the node**:

    ```bash
    ssh ${NODENAME} sudo ls -alR /sastmp/saswork
    ```

    <details><summary>Click here to see the expected output:</summary>

    ```log
    /sastmp/saswork:
    total 0
    drwxr-xr-x 3 4003 2003 4096 Apr 27 13:35 .
    drwxrwxrwx 3 root root 4096 Apr 27 13:35 ..
    drwx------ 2 4003 2003 4096 Apr 27 13:37 SAS_work52E1000000AC_sas-launcher-d4655770-dd8d-4079-8381-1d2269ef4c57-flw74

    /sastmp/saswork/ab7a89c9-0861-4883-92cb-f89f63b6ae21/SAS_work52E1000000AC_sas-launcher-d4655770-dd8d-4079-8381-1d2269ef4c57-flw74:
    total 7272
    -rw-r--r-- 1 4003 2003   46056 Apr 27 13:37 '#LN00015'
    -rw-r--r-- 1 4003 2003       0 Apr 27 13:37 '#LN00016'
    drwx------ 2 4003 2003    4096 Apr 27 13:37  .
    drwxr-xr-x 3 4003 2003    4096 Apr 27 13:35  ..
    -rw-r--r-- 1 4003 2003 6946816 Apr 27 13:37  alex.sas7bdat
    -rw-r--r-- 1 4003 2003   12288 Apr 27 13:35  profile.sas7bcat
    -rw-r--r-- 1 4003 2003   32768 Apr 27 13:35  regstry.sas7bitm
    -rw-r--r-- 1 4003 2003       0 Apr 27 13:35  sas.lck
    -rw-r--r-- 1 4003 2003   12288 Apr 27 13:37  sasgopt.sas7bcat
    -rw-r--r-- 1 4003 2003   20480 Apr 27 13:35  sasmac1.sas7bcat
    -rw-r--r-- 1 4003 2003   20480 Apr 27 13:35  sasmac2.sas7bcat
    -rw-r--r-- 1 4003 2003   20480 Apr 27 13:37  sasmac3.sas7bcat
    -rw-r--r-- 1 4003 2003   20480 Apr 27 13:35  sasmac4.sas7bcat
    -rw-r--r-- 1 4003 2003   20480 Apr 27 13:35  sasmac5.sas7bcat
    -rw-r--r-- 1 4003 2003   20480 Apr 27 13:35  sasmac6.sas7bcat
    -rw-r--r-- 1 4003 2003   20480 Apr 27 13:35  sasmac7.sas7bcat
    -rw-r--r-- 1 4003 2003   20480 Apr 27 13:35  sasmac8.sas7bcat
    -rw-r--r-- 1 4003 2003   20480 Apr 27 13:35  sasmac9.sas7bcat
    -rw-r--r-- 1 4003 2003  143360 Apr 27 13:37  sasmacr.sas7bcat
    -rw-r--r-- 1 4003 2003  131072 Apr 27 13:37  sastmp-000000004.sas7butl
    -rw-r--r-- 1 4003 2003  103424 Apr 27 13:37  sastmp-000000010.sas7bitm
    ```

    </details>

1. If you obtain results that are similar to this, it proves out that you are now using that new location as your saswork.

1. If you now log out of Studio, you will see these SASWORK folders disappear

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
* [07 Deployment Customizations / 07 021 Configuring SASWORK](/07_Deployment_Customizations/07_021_Configuring_SASWORK.md)**<-- you are here**
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
