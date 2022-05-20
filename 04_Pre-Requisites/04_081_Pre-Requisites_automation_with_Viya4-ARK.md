![Global Enablement & Learning](https://gelgitlab.race.sas.com/GEL/utilities/writing-content-in-markdown/-/raw/master/img/gel_banner_logo_tech-partners.jpg)

* [Install pre-reqs](#install-pre-reqs)
* [Run Viya ARKcd to create pre-install reports](#run-viya-arkcd-to-create-pre-install-reports)
* [Surface the report](#surface-the-report)
* [Optional: Running the tool in AKS](#optional-running-the-tool-in-aks)
* [Navigation](#navigation)

# Pre-Requisites Automation

With Viya 3.5, the Viya ARK pre-installation playbook was a very handy tool aimed at checking and implementing any required installation pre-requisites.
For Viya 4, a similar tool is under construction.
The SAS Viya Administration Resource Kit for Container Deployments (SAS Viya ARKcd) provides tools and utilities to help SAS customers prepare for a SAS Viya deployment.

The version of Viya ARKcd pre-req checker tool is available here:
<https://github.com/sassoftware/viya4-ark/tree/master>

<!-- It will become publicly available when the GA release of Viya 4 ships -->

* Let's clone the viya4-ark tool from GitHub

    ```bash
    ## clone the project
    cd ~
    git clone https://github.com/sassoftware/viya4-ark.git

    # but choose a static version!
    cd ~/viya4-ark
    git checkout 1.1.1

    ```


## Install pre-reqs

* We install the Viya ARK pre-reqs with python pip

    ```bash
    #**# paste this block as separate lines into the shell ... it does not seem to complete if you paste the full block
    # first install python 3
    sudo yum install python3 -y

    cd ~/viya4-ark/
    # install Viya ARK pre-reqs
    sudo python3 -m pip install -r requirements.txt

    # install ComplexHTTPServer (to serve HTML reports more easily)
    sudo pip3.6 install ComplexHTTPServer

    ```

## Run Viya ARKcd to create pre-install reports

* Set the KUBECONFIG and run the tool to get usage details

    ```bash
    export KUBECONFIG=~/.kube/config
    # display tool options
    cd ~/viya4-ark/
    python3 viya-ark.py pre-install-report -h
    ```

* You should see something like :

    ```log
    Usage: viya-ark.py pre_install_report <-i|--ingress> <-H|--host> <-p|--port> [<options>]

    Options:
        -i  --ingress=nginx or istio  (Required)Kubernetes ingress controller used for Viya deployment
        -H  --host                    (Required)Ingress host used for Viya deployment
        -p  --port=xxxxx or ""        (Required)Ingress port used for Viya deployment
        -h  --help                    (Optional)Show this usage message
        -n  --namespace               (Optional)Kubernetes namespace used for Viya deployment
        -o, --output-dir="<dir>"      (Optional)Write the report and log files to the provided directory
        -d, --debug                   (Optional)Enables logging at DEBUG level. Default is INFO level
    ```

Otherwise, maybe there is an issue with the version of a python required library :)

* Now it is time to run the tool.

* Generate the pre-install report

    ```bash
    # we need to provide a namespace, so let's create one that we will use for the deployment
    kubectl create ns lab
    cd ~/viya4-ark/
    # run the viya-ark pre-installation tool
    python3 viya-ark.py pre-install-report --ingress=nginx -H $(hostname -f) -p 443 -n lab
    ```

* After a little while, perhaps 1-2 mins, you should see this message:

    ```log
    Created: /home/cloud-user/viya4-ark/viya_pre_install_report_2020-11-03T11_01_52.html
    Created: viya_pre_install_log_2020-11-03T11_01_52.log
    ```

## Surface the report

* Run the commands below to make the report easily available in the web browser.

    ```bash
    cd ~/viya4-ark/
    # create a symlink to the report.
    ln -s viya_pre_install_report_*.html report.html
    # print report URL
    printf "####\nto access the report from your browser, the url will be:
        http://$(hostname -f):1234/report.html
    ###\n"

    ```

* when ready, serve the file with a web server for easy access:

    ```sh
    #start ComplexHTTPServer to serve the report
    python3.6 -m ComplexHTTPServer 1234
    ```

Now, you can open the provided URL in the web browser on the RACE Client machine. Review the pre-installation report to ensure that the Kubernetes cluster meets the requirements.

![pre-install-report](img/pre-install-report.png)

## Optional: Running the tool in AKS

* If running in AKS first get the Ingress host and port information

    ```sh
    NGINXNS="ingress-nginx"
    NGINXCONT="ingress-nginx-controller"
    export INGRESS_HOST=$(kubectl -n $NGINXNS get service $NGINXCONT -o jsonpath='{.status.loadBalancer.ingress[*].ip}')
    export INGRESS_HTTPS_PORT=$(kubectl -n $NGINXNS get service $NGINXCONT -o jsonpath='{.spec.ports[?(@.name=="https")].port}')
    ```

* Then git clone the tool, install the required python libraries (as explained above) and run it:

    ```sh
    python3 viya-ark.py pre-install-report --ingress=nginx -H $INGRESS_HOST -p $INGRESS_HTTPS_PORT -n lab
    ```

<!-- ## surface the report as a pod

TODO later -->

## Navigation

<!-- startnav -->
* [01 Introduction / 01 031 Booking a Lab Environment for the Workshop](/01_Introduction/01_031_Booking_a_Lab_Environment_for_the_Workshop.md)
* [01 Introduction / 01 032 Assess Readiness of Lab Environment](/01_Introduction/01_032_Assess_Readiness_of_Lab_Environment.md)
* [01 Introduction / 01 033 CheatCodes](/01_Introduction/01_033_CheatCodes.md)
* [02 Kubernetes and Containers Fundamentals / 02 131 Learning about Namespaces](/02_Kubernetes_and_Containers_Fundamentals/02_131_Learning_about_Namespaces.md)
* [03 Viya 4 Software Specifics / 03 011 Looking at a Viya 4 environment with Visual Tools DEMO](/03_Viya_4_Software_Specifics/03_011_Looking_at_a_Viya_4_environment_with_Visual_Tools_DEMO.md)
* [03 Viya 4 Software Specifics / 03 051 Create your own Viya order](/03_Viya_4_Software_Specifics/03_051_Create_your_own_Viya_order.md)
* [03 Viya 4 Software Specifics / 03 056 Getting the order with the CLI](/03_Viya_4_Software_Specifics/03_056_Getting_the_order_with_the_CLI.md)
* [04 Pre Requisites / 04 081 Pre Requisites automation with Viya4-ARK](/04_Pre-Requisites/04_081_Pre-Requisites_automation_with_Viya4-ARK.md)**<-- you are here**
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
