![Global Enablement & Learning](https://gelgitlab.race.sas.com/GEL/utilities/writing-content-in-markdown/-/raw/master/img/gel_banner_logo_tech-partners.jpg)

* [Disclaimer](#disclaimer)
* [Important](#important)
* [Register yourself to be part of the STICExnetUsers group](#register-yourself-to-be-part-of-the-sticexnetusers-group)
* [Booking: Duration](#booking-duration)
* [Booking: Choice of Collection](#booking-choice-of-collection)
  * [Collection C1-RACE-VMWare](#collection-c1-vmware)
  * [Collection C1-RACE-Azure](#collection-c1-azure)
  * [Collection C2 (_AUTODEPLOY_)](#collection-c2-autodeploy)
* [Environment access](#environment-access)
  * [OS Credentials](#os-credentials)
  * [Viya Credentials](#viya-credentials)
  * [Readiness](#readiness)
* [Navigation](#navigation)

# Booking a Lab Environment for the Workshop

## Disclaimer

* The Lab environment provided (in RACE) is a constant work in progress, to keep things updated to the latest versions
* This can sometimes lead to issues, that are usually resolved quickly
* You should not attempt to save your running Collection after you are done with the exercises
* Instead, you should get into the habit of booking a fresh collection each time
* If you need to skip some hands-on, you can use the "[cheatcodes](./01_033_CheatCodes.md)" method.

## Important

* Some Lab Environments can take a significant amount of time to fully come online.
* You will probably be able to access your Servers before all the software on it is fully functional.
* Do make sure that you follow the instructions here to assess the state of [readiness](01_Introduction/02_Assess_Readiness_of_Lab_Environment.md) of your particular environment.

## Register yourself to be part of the STICExnetUsers group

* If you are not yet a member of the **STICExnetUsers** group, you need to join it.
  * [Click here](mailto:dlistadmin@wnt.sas.com?subject=Subscribe%20STICEXNETUsers) to prepare an email request to join **STICExnetUsers** group
  * This should open up a new e-mail
    * to the address: `dlistadmin@wnt.sas.com`
    * with the subject: `Subscribe STICEXNETUsers`
  * Send the email as-is, without any changes
* Once the email is sent, you will be notified via email of the creation of the account.
* Your account membership should be updated and ready for use within 1 hour
* Sometimes, it takes much longer than 1 hour for this group membership to propagate through the network.
* To expedite the group membership, simply log out of the SAS network and log back in).
* Until the group membership change occurs, you won't be able reserve the environment.

## Booking: Duration

* You are allowed to change the Start and Stop date of your booking
* You are allowed to change the Stop date after the reservation has started
  * This may not always be possible, in case another reservation is schedule to re-use your machines.
* You **SHOULD NOT** update the Reservation Comment field!
  * we sometimes parse that text to influence the machine's behavior

## Booking: Choice of Collection

For the Viya 4 Deployment Workshop, you should be booking the **C1** Collection mentioned below.

### Collection C1-RACE-VMWare

This collection is used to practice deploying Viya from scratch on a Kubernetes Cluster

* This Collection has 1 Windows "jumphost" and 5 Linux Servers
* The 5 linux servers form a fully functional Kubernetes cluster
* [Book C1 VMWare](http://race.exnet.sas.com/Reservations?action=new&imageId=329302&imageKind=C&comment=C1-VMW%20-%20Viya%204%20Deployment%20-%205-Machine%20K8s%20Cluster&purpose=PST&sso=PSGEL255&schedtype=SchedTrainEDU&startDate=now&endDateLength=0&discardonterminate=y), the "blank", 5-node K8S Cluster.

### Collection C1-RACE-Azure

* **ONLY IF YOU ARE UNABLE TO BOOK THE VMWARE COLLECTION**
* This collection uses Azure based machines which are part of the wider RACE network
* It should only be used when the VMWare based RACE machines are not available 
* You should only book the collection for 4 hours at a time, as there is a cost to SAS when these machines are used
* [Book C1 Azure](http://race.exnet.sas.com/Reservations?action=new&imageId=308491&imageKind=C&comment=C1-AZU%20-%20Viya%204%20Deployment%20-%205-Machine%20K8s%20Cluster&purpose=PST&sso=PSGEL255&schedtype=SchedTrainEDU&startDate=now&endDateLength=0&discardonterminate=y), the "blank", 5-node K8S Cluster.

### Collection C2 (_AUTODEPLOY_)

This collection will auto-deploy Viya 4 for you. It can be used as a starting point when testing scenarios that differ from the default deployment.

* This Collection has 1 Windows "jumphost" and 5 Linux Servers
* The 5 linux servers form a fully functional Kubernetes cluster
* As soon as Kubernetes is ready, a Vanilla Viya 4 Environment will be started on it
* [Book C2-VMW-LTS](http://race.exnet.sas.com/Reservations?action=new&imageId=329302&imageKind=C&comment=_AUTODEPLOY_LTS_%20C2-VMW%20Viya%204%20Deployment&purpose=PST&sso=PSGEL255&schedtype=SchedTrainEDU&startDate=now&endDateLength=0&discardonterminate=y) the "autodeploy basic Viya 4 - LTS" on a 5-node K8S Cluster
* [Book C2-VMW-stable](http://race.exnet.sas.com/Reservations?action=new&imageId=329302&imageKind=C&comment=_AUTODEPLOY_STABLE_%20C2-VMW%20Viya%204%20Deployment&purpose=PST&sso=PSGEL255&schedtype=SchedTrainEDU&startDate=now&endDateLength=0&discardonterminate=y) the "autodeploy basic Viya 4 - stable" on a 5-node K8S Cluster
  * **DO NOT** change the reservation comment

## Environment access

Each environment (RACE Collection) is made up of:

* One Windows Client Machine
* 5 Centos Linux Machines

* You MUST connect to the Windows Client machine first
  * u: `.\student`
  * p: `Metadata0`
* From that Windows Jump Host, you can access your Linux machines which is defined as sasnode01 in MobaXTerm.
  * u: `cloud-user`
  * p: `lnxsas`

### OS Credentials

The most commonly needed OS credentials for the servers in the collection are:

| Machine    | User:      | Password:   | Connection type |
|------------|------------|-------------|-----------------|
| Linux      | `cloud-user` | `lnxsas`      | SSH             |
| Windows    | `.\student`  | `Metadata0`   | RDP             |

### Viya Credentials

The credentials to access Viya are:

| User:      | Password:       |
|------------|-----------------|
| `sasboot`  | `lnxsas`        |
| `sasadm`   | `lnxsas`        |
| `geladm`   | `lnxsas`        |
| `alex`     | `lnxsas`        |

### Readiness

* Do make sure that you follow the instructions here to assess the state of [readiness](/01_Introduction/01_032_Assess_Readiness_of_Lab_Environment.md) of your particular environment.

## Navigation

<!-- startnav -->
* [01 Introduction / 01 031 Booking a Lab Environment for the Workshop](/01_Introduction/01_031_Booking_a_Lab_Environment_for_the_Workshop.md)**<-- you are here**
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


