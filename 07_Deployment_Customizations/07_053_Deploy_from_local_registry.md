![Global Enablement & Learning](https://gelgitlab.race.sas.com/GEL/utilities/writing-content-in-markdown/-/raw/master/img/gel_banner_logo_tech-partners.jpg)

# Deploy from local registry

* [Clear things up](#clear-things-up)
* [Prepare deployment](#prepare-deployment)
  * [gelldap and gelmail](#gelldap-and-gelmail)
  * [Order and assets](#order-and-assets)
  * [create mirror file override](#create-mirror-file-override)
  * [create secret to authenticate to local registry](#create-secret-to-authenticate-to-local-registry)
  * [Crunchy postgres needs a special file](#crunchy-postgres-needs-a-special-file)
  * [Creating a TLS-related file in `./site-config/`](#creating-a-tls-related-file-in-site-config)
  * [Create file for RWX Storage Class](#create-file-for-rwx-storage-class)
  * [create kustomization.yaml](#create-kustomizationyaml)
* [Deployed the "mirrored" environment](#deployed-the-mirrored-environment)
* [Generate the URLs for the environment](#generate-the-urls-for-the-environment)
* [Waiting for it](#waiting-for-it)
* [Validate that deployment is working](#validate-that-deployment-is-working)
* [Important: restore access to cr.sas.com](#important-restore-access-to-crsascom)
* [Navigation](#navigation)

## Clear things up

1. remove namespaces if they exist

    ```bash
    kubectl delete ns mirrored
    ```

1. delete other ns

    ```sh
    kubectl delete ns lab dailymirror testready dev gelenv
    ```

1. Remove all cached images from all machines:

    ```bash
    ansible all -m shell -a "docker image prune -a --force | grep reclaimed" -b

    ```

1. Cut off access to the SAS repositories

    ```sh
    ## this will prevent you from accessing the "default" viya images.
    ansible sasnodes -m lineinfile -b \
        -a " dest=/etc/hosts \
            regexp='cr\.sas\.com' \
            line='999.999.999.999 cr.sas.com' \
            state=present \
            backup=yes " \
            --diff

    ```

## Prepare deployment

1. create a namespace

    ```bash
    kubectl create ns mirrored

    ```

1. and a working directory

    ```bash
    mkdir -p ~/project/deploy/mirrored
    mkdir -p ~/project/deploy/mirrored/site-config

    ```

### gelldap and gelmail

```bash

cd ~/project/
git clone https://gelgitlab.race.sas.com/GEL/utilities/gelldap.git
cd ~/project/gelldap/
git fetch --all
GELLDAP_BRANCH=int_images
git switch ${GELLDAP_BRANCH}

cd ~/project/gelldap/
kustomize build ./no_TLS/ | kubectl -n mirrored apply -f -

cp ~/project/gelldap/no_TLS/gelldap-sitedefault.yaml \
       ~/project/deploy/mirrored/site-config/

```

### Order and assets

* This was generated earlier for us:

    ```bash
    ORDER=9CFHCQ
    CADENCE_NAME='stable'
    CADENCE_VERSION='2020.1.5'
    #CADENCE_RELEASE='20210318.1616036841383'

    ORDER_FILE=$(ls ~/orders/ \
        | grep ${ORDER} \
        | grep ${CADENCE_NAME} \
        | grep ${CADENCE_VERSION} \
        | sort \
        | tail -n 1 \
        )
    echo ${ORDER_FILE}


    #ORDER_FILE=$(ls ~/orders/ | grep ${ORDER} | grep ${CADENCE_VERSION} | grep ${CADENCE_RELEASE} )

    cp ~/orders/${ORDER_FILE} ~/project/deploy/mirrored/
    cd  ~/project/deploy/mirrored/
    ls -al ~/project/deploy/mirrored/
    ```

* will show (although the cadence release will change over time):

    ```log
    total 784
    drwxrwxr-x 4 cloud-user cloud-user    178 Mar 29 10:44 .
    drwxrwxr-x 4 cloud-user cloud-user     33 Mar 29 10:10 ..
    drwxrwxr-x 8 cloud-user cloud-user    140 Mar 29 10:11 sas-bases
    -rw-rw-r-- 1 cloud-user cloud-user   4205 Mar 29 10:11 SASViyaV4_9CHTZV_certs.zip
    -rw-rw-r-- 1 cloud-user cloud-user 793998 Mar 29 10:11 SASViyaV4_9CHTZV_stable_2020.1.4_20210326.1616785638833_deploymentAssets_2021-03-27T060202.tgz
    drwxrwxr-x 2 cloud-user cloud-user     38 Mar 29 10:45 site-config
    ```

### create mirror file override

1. this will later be included in the kustomization.yaml

    ```bash
    sed -e "s/{{\ MIRROR\-HOST\ }}/harbor.$(hostname -f):443\/viya/g" \
            ~/project/deploy/mirrored/sas-bases/examples/mirror/mirror.yaml \
            > ~/project/deploy/mirrored/site-config/mirror.yaml

    ```

1. Please review the above command with care. As well as the source file and the generated file.

### create secret to authenticate to local registry

these images can not be puled from harbor without authentication.

1. this creates a file you put in site-config that contains the required credentials

    ```bash
    # put your registry access into variables
    harbor_user=$(cat ~/exportRobot.json | jq -r .name)
    harbor_pass=$(cat ~/exportRobot.json | jq -r .token)

    # create a new secret and put the info into a variable
    # - this does not really create secret on the server:
    # notice the --dry-run option
    CR_SAS_COM_SECRET="$(kubectl -n mirrored create secret docker-registry cr-access \
        --docker-server=harbor.$(hostname -f):443 \
        --docker-username=${harbor_user} \
        --docker-password=${harbor_pass} \
        --dry-run=client -o json | jq -r '.data.".dockerconfigjson"')"

    echo $CR_SAS_COM_SECRET | base64 --decode
    echo -n $CR_SAS_COM_SECRET | base64 --decode > ~/project/deploy/mirrored/site-config/harbor_access.json

    ```

### Crunchy postgres needs a special file

1. Following the instructions in the postgres README file, we are told to create this file

    ```bash
    cd ~/project/deploy/mirrored

    mkdir -p ./site-config/postgres

    cat ./sas-bases/examples/configure-postgres/internal/custom-config/postgres-custom-config.yaml | \
        sed 's|\-\ {{\ HBA\-CONF\-HOST\-OR\-HOSTSSL\ }}|- hostssl|g' | \
        sed 's|\ {{\ PASSWORD\-ENCRYPTION\ }}| scram-sha-256|g' \
        > ./site-config/postgres/postgres-custom-config.yaml

    ```

### Creating a TLS-related file in `./site-config/`

By default since the 2020.0.6 version, all internal communications are TLS encrypted.

* Prepare the TLS configuration, according to the doc

    ```bash
    cd ~/project/deploy/mirrored
    mkdir -p ./site-config/security/
    # create the certificate issuer called "sas-viya-issuer"
    sed 's|{{.*}}|sas-viya-issuer|g' ./sas-bases/examples/security/cert-manager-provided-ingress-certificate.yaml  \
        > ./site-config/security/cert-manager-provided-ingress-certificate.yaml
    ```

### Create file for RWX Storage Class

1. In stable-2020.1.4, we are instructed to create this file with the name of a Kubernetes Storage Class that is capable of doing RWX Volumes.

1. do a `kubectl get sc` to see it

1. In our environment, it's called "nfs-client"

1. So to create that file, we do:

    ```bash
    bash -c "cat << EOF > ~/project/deploy/mirrored/site-config/storageclass.yaml
    ---
    kind: RWXStorageClass
    metadata:
      name: wildcard
    spec:
      storageClassName: nfs-client
    EOF"

    ```

### create kustomization.yaml

1. now, this:

    ```bash
    INGRESS_SUFFIX=$(hostname -f)
    echo $INGRESS_SUFFIX

    bash -c "cat << EOF > ~/project/deploy/mirrored/kustomization.yaml
    ---
    namespace: mirrored
    resources:
      - sas-bases/base
      - sas-bases/overlays/cert-manager-issuer     # TLS
      - sas-bases/overlays/network/ingress
      - sas-bases/overlays/network/ingress/security   # TLS
      - sas-bases/overlays/internal-postgres
      - sas-bases/overlays/crunchydata
      - sas-bases/overlays/cas-server
      - sas-bases/overlays/update-checker       # added update checker
      # - sas-bases/overlays/cas-server/auto-resources    # CAS-related
    configurations:
      - sas-bases/overlays/required/kustomizeconfig.yaml  # required for 0.6
    transformers:
      - sas-bases/overlays/network/ingress/security/transformers/product-tls-transformers.yaml   # TLS
      - sas-bases/overlays/network/ingress/security/transformers/ingress-tls-transformers.yaml   # TLS
      - sas-bases/overlays/network/ingress/security/transformers/backend-tls-transformers.yaml   # TLS
      - sas-bases/overlays/required/transformers.yaml
      - sas-bases/overlays/internal-postgres/internal-postgres-transformer.yaml
      - site-config/security/cert-manager-provided-ingress-certificate.yaml     # TLS
      # - sas-bases/overlays/cas-server/auto-resources/remove-resources.yaml    # CAS-related
      - site-config/mirror.yaml
      #- sas-bases/overlays/scaling/zero-scale/phase-0-transformer.yaml
      #- sas-bases/overlays/scaling/zero-scale/phase-1-transformer.yaml
    patches:        ## this is new in stable-2020.1.4
      - path: site-config/storageclass.yaml
        target:
          kind: PersistentVolumeClaim
          annotationSelector: sas.com/component-name in (sas-backup-job,sas-data-quality-services,sas-commonfiles)
    configMapGenerator:
      - name: input
        behavior: merge
        literals:
          - IMAGE_REGISTRY=harbor.$(hostname -f):443/viya
      - name: ingress-input
        behavior: merge
        literals:
          - INGRESS_HOST=mirrored.${INGRESS_SUFFIX}
      - name: sas-shared-config
        behavior: merge
        literals:
          - SAS_SERVICES_URL=https://mirrored.${INGRESS_SUFFIX}
      - name: sas-go-config
        behavior: merge
        literals:
          - SAS_BOOTSTRAP_HTTP_CLIENT_TIMEOUT_REQUEST='15m'
    secretGenerator:
      - name: sas-image-pull-secrets
        behavior: replace
        type: kubernetes.io/dockerconfigjson
        files:
          - .dockerconfigjson=site-config/harbor_access.json
      - name: sas-consul-config            ## This injects content into consul. You can add, but not replace
        behavior: merge
        files:
          - SITEDEFAULT_CONF=site-config/gelldap-sitedefault.yaml ## with 2020.1.5, the sitedefault.yaml config becomes a secretGenerator
      # # This is to fix an issue that only appears in RACE Exnet.
      # # Do not do this at a customer site

    generators:
      - site-config/postgres/postgres-custom-config.yaml

    EOF"

    ```

## Deployed the "mirrored" environment

1. follow the usual 3-step apply pattern:

    ```bash
    cd  ~/project/deploy/mirrored/

    kustomize build -o site.yaml

    NS=mirrored
    kubectl  -n ${NS}  apply   --selector="sas.com/admin=cluster-wide" -f site.yaml
    kubectl wait  --for condition=established --timeout=60s -l "sas.com/admin=cluster-wide" crd
    kubectl  -n ${NS} apply  --selector="sas.com/admin=cluster-local" -f site.yaml --prune
    kubectl  -n ${NS} apply  --selector="sas.com/admin=namespace" -f site.yaml --prune

    # kubectl  -n ${NS} apply -f site.yaml

    ```

## Generate the URLs for the environment

```bash
NS=mirrored
DRIVE_URL="https://$(kubectl -n ${NS} get ing sas-drive-app -o custom-columns='hosts:spec.rules[*].host' --no-headers)/SASDrive/"
echo $DRIVE_URL

printf "\n* [Viya Drive (mirrored) URL (HTTPS)](${DRIVE_URL} )\n\n" | tee -a /home/cloud-user/urls.md
```

## Waiting for it

```sh

gel_OKViya4 -n mirrored --wait -ps
# or
kubectl wait -n mirrored --for=condition=ready pod --selector='app.kubernetes.io/name=sas-readiness'  --timeout=2700s

```

## Validate that deployment is working

log in and use with the environment.

## Important: restore access to cr.sas.com

If you want to be able to do the other exercises, you'll need to restore the access to cr.sas.com that we arbitrarily blocked.

1. do this:

    ```bash

    # re-enable
    ansible sasnodes -m lineinfile -b \
        -a " dest=/etc/hosts \
            regexp='cr\.sas\.com' \
            line='999.999.999.999 cr.sas.com' \
            state=absent \
            backup=yes " \
            --diff

    ```

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
* [07 Deployment Customizations / 07 053 Deploy from local registry](/07_Deployment_Customizations/07_053_Deploy_from_local_registry.md)**<-- you are here**
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
