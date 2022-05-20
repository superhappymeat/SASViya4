![Global Enablement & Learning](https://gelgitlab.race.sas.com/GEL/utilities/writing-content-in-markdown/-/raw/master/img/gel_banner_logo_tech-partners.jpg)

# Accessing the Environments

- [Get registered for SAS resources in AWS](#get-registered-for-sas-resources-in-aws)
- [Reserve a collection in RACE as a workspace](#reserve-a-collection-in-race-as-a-workspace)
- [Setup SSH keys where you need them](#setup-ssh-keys-where-you-need-them)
- [Setup AWS keys](#setup-aws-keys)
- [Navigation](#navigation)

## Get registered for SAS resources in AWS

1. Request access to the SAS-owned AWS account.

   * [Send this email](mailto:dlistadmin@wnt.sas.com?subject=SUBSCRIBE%20AWS-182696677754-testers) to join the **testers** role of the **sas-salesenabletest** account

   * It might take several minutes to process

   * [Logon to the federated SAS account on AWS](http://go.sas.com/aws) using your SAS credentials (if prompted)

   * If you already are a member of other roles, then you'll be prompted to select which to use. Confirm you see (and choose):

     ![](img/2021-04-20_16-55-24.png)

## Reserve a collection in RACE as a workspace

<!-- Originally using collection no. 226618 -->
2. Get RACE collection: [Win client + Linux host with k3s](http://race.exnet.sas.com/Reservations?action=new&imageId=333991&imageKind=C&comment=Viya%204%20-%20Single%20Machine&purpose=PST&sso=PSGEL255&schedtype=SchedTrainEDU&startDate=now&endDateLength=1)

   * Login to the Windows machine (u: `.\Student`, pw: `Metadata0`)
   * On the Windows host, open the MobaXterm app and open the `sasnode01` session with credentials (u: `cloud-user`, pw: `lnxsas`).
   * Note your Linux host's FQDN. It will be similar to either:
     * `pdcesx#####.race.sas.com`
     * `rext##-###.race.sas.com`

## Setup SSH keys where you need them

3. Setup on `cldlgn.fyi.sas.com` 

   * From your PC (not the RACE hosts), use [PuTTY](https://www.chiark.greenend.org.uk/~sgtatham/putty/latest.html) (or similar terminal application) to open an SSH connection to `cldlgn.fyi.sas.com` and login using `<your CARYNT userid>`

   * Tokenize your Linux host in RACE as the destination

      ```bash
      # As <your CARYNT userid> on cldlgn.fyi.sas.com

      # Enter appropriate values for the target host in RACE
      user=cloud-user    
      host=<HOST>.race.sas.com   # e.g. pdcesx01234.race.sas.com
      ```

     This will allow the `$user@$host` references in later code to work.
  
   * Create a private/public keypair

       ```bash
       # if the id_rsa file doesn't exist, then create it
       [[ -f ~/.ssh/id_rsa ]] || ssh-keygen -q -t rsa -b 1024 -N '' -f ~/.ssh/id_rsa
       ```

       The `id_rsa` key file name is nice because it's referenced by subsequent SSH/SCP by default. But you can specify a different key name if you want. If you do, remember to use `-i ~/.ssh/id_YourCustomName` when invoking SSH/SCP.

   * Add the public part of the key just created as a local auth'd key

      ```bash
      pubkey=`cat ~/.ssh/id_rsa.pub`

      echo $pubkey >> ~/.ssh/authorized_keys
      ```

   * Create the necessary .ssh directory targets on the Linux host in RACE

      ```bash
      ssh ${user}@${host} "mkdir -p ~/.ssh && chmod 700 ~/.ssh"
      ```

      You'll be prompted:

      * to accept the `$host`'s fingerprint (if first time using SSH to connect to it)
      * for the `$user`'s password on the `$host`.

   * Add the public key to the list of authorized keys on the Linux host in RACE.

      ```bash
      ssh ${user}@${host} "echo $pubkey >> ~/.ssh/authorized_keys"
      ```

      You'll be prompted for the `$user`'s password on the `$host` again.  

   * Validate

      ```bash
      ssh ${user}@${host} hostname
      ```

      And this time, you should get the response back _without_ providing the `$user`'s password.

   * Be certain your validation works ... else the `autorenew-getawskey` utility will not.

## Setup AWS keys 

4. Authenticate yourself to get AWS keys

   Inside SAS, we have a utility called `getawskey` that leverages your kerberos tickets to automatically create AWS tokens for use with the  AWS CLI. Currently, that utility seems capable of only creating tokens which last 1 hour. 

   As a workaround, we created a script to automatically re-run `getawskey` every hour on your behalf. It's called [autorenew-getawskey](https://gitlab.sas.com/rocoll/autorenew-getawskey). 

   So it's your choice - use the automatic approach to work all day without interruption, or scroll down to perform the manual steps once an hour for as long as you need. ;)

   **AUTOMATIC**

   ```bash
   # As <your CARYNT userid> on cldlgn.fyi.sas.com

   # Download the autorenew-getawskey tool
   git clone https://gitlab.sas.com/rocoll/autorenew-getawskey.git

   cd autorenew-getawskey

   # The getawskey utility relies on kerberos tickets to authenticate you to AWS
   kinit

   # Specify the number of hours to renew your AWS tokens,
   # your userid on RACE (cloud-user), and the hostname of
   # your RACE Linux host (pdcesx#####.race.sas.com).
   ./autorenew-getawskey.sh 8 $user $host
    ```

   If you have multiple AWS IAM roles, then prompted with:

   ```log
   [0]: arn:aws:iam::182696677754:role/admin
   [1]: arn:aws:iam::738386057074:role/wwm-cons
   [2]: arn:aws:iam::738386057074:role/viyadeploymentworkshop
   [3]: arn:aws:iam::182696677754:role/testers
   ```

   Select `role/testers`. For me, that's option [`3`]. But it might be a different number for you - if this prompt is presented at all.

   Results:
   ```log
   rocoll@cldlgn00.unx.sas.com> ./autorenew-getawskey.sh 8 cloud-user pdcesx00000.race.sas.com

   INFO: Start off by creating the initial AWS tokens...
   [0]: arn:aws:iam::182696677754:role/admin
   [1]: arn:aws:iam::738386057074:role/wwm-cons
   [2]: arn:aws:iam::738386057074:role/viyadeploymentworkshop
   [3]: arn:aws:iam::182696677754:role/testers
   Please choose a role to assume:	3
   You selected: 3
   INFO[0001] Create credentials for profile: default      

   INFO: Working with AWS Access Key ID: ASIASVCMSCF5PYBQJKES. Slick!
   INFO: Creating the AWS config file. Because I said so, that's why.

   INFO: Setting the daemon loose for 8 hours. Lucky!

   Now you can enjoy using AWS as cloud-user on pdcesx02099.race.sas.com. Or you can at least try.
   ```

   Skip the manual tasks, proceed to Step 5.

   <hr>

   or **MANUALLY, EVERY HOUR**

   ```bash
   # As <your CARYNT userid> on cldlgn.fyi.sas.com

   # The getawskey utility relies on kerberos tickets to authenticate you to AWS
   kinit

   # Run the getawskey utility 
   getawskey

   # by default, getawskey generates AWS tokens with a 1-hour lifespan
   ```

   If you have multiple AWS IAM roles, then prompted with:

   ```log
   [0]: arn:aws:iam::182696677754:role/admin
   [1]: arn:aws:iam::738386057074:role/wwm-cons
   [2]: arn:aws:iam::738386057074:role/viyadeploymentworkshop
   [3]: arn:aws:iam::182696677754:role/testers
   ```

   Select `role/testers`. 
   
   Set env vars, if needed:

   ```bash
   export AWS_ACCESS_KEY_ID=`aws configure get aws_access_key_id`
   export AWS_SECRET_ACCESS_KEY=`aws configure get aws_secret_access_key`
   export AWS_SESSION_TOKEN=`aws configure get aws_session_token`
   ```

   and/or place values in `~/.aws/credentials` file:

   ```bash
   # ensure the dir exists
   mkdir -p ~/.aws

   now=`date`

   # credentials file
   tee  ~/.aws/credentials > /dev/null << EOF
   # generated ${now} - good for 1 hour
   [default]
   aws_secret_access_key = ${AWS_SECRET_ACCESS_KEY}
   aws_access_key_id     = ${AWS_ACCESS_KEY_ID}
   aws_session_token     = ${AWS_SESSION_TOKEN}
   EOF

   # config file
   tee  ~/.aws/config2 > /dev/null << EOF
   [default]
   region = us-east-1
   output = table
   EOF
   ```

   Then repeat these **manual steps** every hour, copying the resulting `.aws` directory to the cloud-user's home directory on your Linux host in RACE.

5. Validate your AWS tokens are valid

   ```bash
   # As <your CARYNT userid> on cldlgn.fyi.sas.com

   # Look for expected output, no errors
   aws configure list

   aws s3 ls

   # Ask AWS to identify you
   aws sts get-caller-identity  --output json
   # also try output types of "text" and "table"
   ```
   
6. Confirm the AWS files arrive on your Linux host in RACE

   * Look for the AWS configuration files in your home directory
  
     ```bash
     # as cloud-user on your Linux host in RACE

     ls -l ~/.aws
     ```

     Results:

     ```log
     [cloud-user@pdcesx00000 ~]$ ls -l ~/.aws
     total 12
     -rw-r--r-- 1 cloud-user cloud-user  200 May 13 00:08 awskeyconfig
     -rw-r--r-- 1 cloud-user cloud-user   67 May 13 00:08 config
     -rw-r--r-- 1 cloud-user cloud-user 1144 May 13 00:08 credentials
     ```

# End

You've gained access to the SAS-managed area of Amazon Web Services. And you've established a process for getting the AWS tokens on to the Linux host in RACE for this exercise.

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
* [12 Amazon EKS Deployment / 12 010 Access Environments](/12_Amazon_EKS_Deployment/12_010_Access_Environments.md)**<-- you are here**
* [12 Amazon EKS Deployment / 12 020 Provision Resources](/12_Amazon_EKS_Deployment/12_020_Provision_Resources.md)
* [12 Amazon EKS Deployment / 12 030 Deploy SAS Viya](/12_Amazon_EKS_Deployment/12_030_Deploy_SAS_Viya.md)
* [13 Google GKE Deployment / 13 011 Creating a GKE Cluster](/13_Google_GKE_Deployment/13_011_Creating_a_GKE_Cluster.md)
* [13 Google GKE Deployment / 13 021 Performing Prereqs in GKE](/13_Google_GKE_Deployment/13_021_Performing_Prereqs_in_GKE.md)
* [13 Google GKE Deployment / 13 031 Deploying Viya 4 on GKE](/13_Google_GKE_Deployment/13_031_Deploying_Viya_4_on_GKE.md)
* [13 Google GKE Deployment / 13 041 Full Automation of GKE Deployment](/13_Google_GKE_Deployment/13_041_Full_Automation_of_GKE_Deployment.md)
* [13 Google GKE Deployment / 13 099 Fast track with cheatcodes](/13_Google_GKE_Deployment/13_099_Fast_track_with_cheatcodes.md)
<!-- endnav -->
