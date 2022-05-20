![Global Enablement & Learning](https://gelgitlab.race.sas.com/GEL/utilities/writing-content-in-markdown/-/raw/master/img/gel_banner_logo_tech-partners.jpg)

# Deploy the "gelenv" GEL order (all products)

* This is not for human consumption.
* This is an automated way of deploying a template environment.
* This is used by the shared collection.
* This is also used by some of the authentication collections.
* This is also used by the admin and migration collections.

Just execute:

```sh

#testing
cd ~/PSGEL255-deploying-viya-4.0.1-on-kubernetes/
git pull
#git reset --hard origin/master
bash -x ~/PSGEL255-deploying-viya-4.0.1-on-kubernetes/scripts/loop/GEL.02.CreateCheatcodes.sh start
bash -x ~/PSGEL255-deploying-viya-4.0.1-on-kubernetes/01_Introduction/01_000_gelenv_order.sh

```


* [thinking](#thinking)
* [get order](#get-order)
* [IF_BEGIN for Shared Collection](#if_begin-for-shared-collection)
  * [Labels and taints](#labels-and-taints)
  * [CADENCE: LTS](#cadence-lts)
    * [default values for variables](#default-values-for-variables)
    * [wipe namespace](#wipe-namespace)
    * [prep NS](#prep-ns)
    * [ldap](#ldap)
    * [Choose order](#choose-order)
    * [Daily update-checker run](#daily-update-checker-run)
    * [MPP CAS:](#mpp-cas)
    * [Crunchy postgres needs a special file](#crunchy-postgres-needs-a-special-file)
    * [TLS work](#tls-work)
    * [Kustomization](#kustomization)
    * [build](#build)
    * [apply](#apply)
    * [Urls](#urls)
    * [Do one with HA-enabled](#do-one-with-ha-enabled)
  * [CADENCE: Stable](#cadence-stable)
    * [default values for variables](#default-values-for-variables-1)
    * [wipe namespace](#wipe-namespace-1)
    * [prep namespace](#prep-namespace)
    * [ldap](#ldap-1)
    * [get order](#get-order-1)
    * [Daily update-checker run](#daily-update-checker-run-1)
    * [MPP CAS:](#mpp-cas-1)
    * [Crunchy postgres needs a special file](#crunchy-postgres-needs-a-special-file-1)
    * [TLS work](#tls-work-1)
    * [Kustomization](#kustomization-1)
    * [build](#build-1)
    * [apply](#apply-1)
    * [Urls](#urls-1)
    * [Do one with HA-enabled](#do-one-with-ha-enabled-1)
* [IF_END for Shared Collection](#if_end-for-shared-collection)
* [IF_BEGIN for 5-machine-collection](#if_begin-for-5-machine-collection)
  * [Labels and taints](#labels-and-taints-1)
  * [CADENCE: LTS](#cadence-lts-1)
    * [default values for variables](#default-values-for-variables-2)
    * [prep NS](#prep-ns-1)
    * [ldap](#ldap-2)
    * [Choose order](#choose-order-1)
    * [Daily update-checker run](#daily-update-checker-run-2)
    * [MPP CAS:](#mpp-cas-2)
    * [Crunchy postgres needs a special file](#crunchy-postgres-needs-a-special-file-2)
    * [TLS work](#tls-work-2)
    * [Kustomization-lts](#kustomization-lts)
    * [build](#build-2)
    * [apply LTS, conditionally on description](#apply-lts-conditionally-on-description)
    * [Urls](#urls-2)
  * [CADENCE: Stable](#cadence-stable-1)
    * [default values for variables](#default-values-for-variables-3)
    * [prep namespace](#prep-namespace-1)
    * [ldap](#ldap-3)
    * [get order](#get-order-2)
    * [Daily update-checker run](#daily-update-checker-run-3)
    * [MPP CAS:](#mpp-cas-3)
    * [Crunchy postgres needs a special file](#crunchy-postgres-needs-a-special-file-3)
    * [TLS work](#tls-work-3)
    * [Kustomization-stable](#kustomization-stable)
    * [build](#build-3)
    * [apply STABLE, conditional on description](#apply-stable-conditional-on-description)
    * [Urls](#urls-3)
* [IF_END for 5-machine-collection](#if_end-for-5-machine-collection)
* [IF_BEGIN for 1-machine-collection](#if_begin-for-1-machine-collection)
  * [Labels and taints](#labels-and-taints-2)
  * [CADENCE: LTS](#cadence-lts-2)
    * [default values for variables](#default-values-for-variables-4)
    * [prep NS](#prep-ns-2)
    * [ldap](#ldap-4)
    * [Choose order](#choose-order-2)
    * [Crunchy postgres needs a special file](#crunchy-postgres-needs-a-special-file-4)
    * [make is smaller footprint:](#make-is-smaller-footprint)
    * [TLS work](#tls-work-4)
    * [Kustomization](#kustomization-2)
    * [build and apply lts for single-machine](#build-and-apply-lts-for-single-machine)
    * [Urls](#urls-4)
* [IF_END for 1-machine-collection](#if_end-for-1-machine-collection)
* [IF_BEGIN for Admin Autodeploy Collection](#if_begin-for-admin-autodeploy-collection)
  * [run the script](#run-the-script)
* [IF_END Admin Autodeploy Collection](#if_end-admin-autodeploy-collection)
* [IF_BEGIN for Migration Autodeploy Collection](#if_begin-for-migration-autodeploy-collection)
  * [run the script](#run-the-script-1)
* [IF_END Migration Autodeploy Collection](#if_end-migration-autodeploy-collection)

## thinking

* single machine:
  * make it small enough to fit
* 5-machine collection:
  * make it a "template" to start from
  * no HA
  * all defaults
  * LTS or stable, as an option
* 11-machine
  * both LTS and Stable
  * both HA
  * but boots as quick as possible
    * Start LTS, non-ha first
    * wait for ready
    * Start Stable, non-ha
    * wait for ready
    * go back to LTS and add HA
    * go back to stable and add HA


## get order

1. copy order stuff

    ```bash

    # update orders:
    bash -x ~/PSGEL255-deploying-viya-4.0.1-on-kubernetes/scripts/loop/GEL.23.copy.orders.sh start
    ```

## IF_BEGIN for Shared Collection

1. begin the if

    ```bash
    source <( cat /opt/raceutils/.bootstrap.txt  )
    source <( cat /opt/raceutils/.id.txt  )

    #if  [ "$collection_size" -gt "10"  ] ; then
    if [[ "$description" == *"_SHARED_"* ]]  ; then

    ```


### Labels and taints

* clear it all up

    ```bash
    kubectl label nodes \
        intnode01 intnode02 intnode03 intnode04 intnode05 intnode06 intnode07 intnode08 intnode09 intnode10 intnode11  \
        workload.sas.com/class-          --overwrite
    kubectl taint nodes \
        intnode01 intnode02 intnode03 intnode04 intnode05 intnode06 intnode07 intnode08 intnode09 intnode10 intnode11  \
        workload.sas.com/class-          --overwrite
    ```

* start with labels

    ```bash
    kubectl label nodes \
         intnode01   \
        workload.sas.com/class=compute          --overwrite
    kubectl label nodes \
         intnode02    \
         intnode03    \
        workload.sas.com/class=stateful          --overwrite
    kubectl label nodes \
        intnode04   \
        intnode05   \
        intnode06   \
        intnode07   \
        intnode08   \
        intnode09   \
        intnode10   \
        intnode11   \
        workload.sas.com/class=stateless          --overwrite

    #kubectl taint nodes \
    #    intnode01 \
    #    workload.sas.com/class=cas:NoSchedule --overwrite


    ```

* no taints yet


### CADENCE: LTS

#### default values for variables

```bash
    NS=${NS:-gelenv-lts}
    CADENCE_NAME='lts'
    CADENCE_VERSION='2020.1'
    ORDER='9CDZDD'
    INGRESS_PREFIX=${INGRESS_PREFIX:-${NS}}
    FOLDER_NAME=${FOLDER_NAME:-~/project/deploy/${NS}}
    READINESS_TIMEOUT=${READINESS_TIMEOUT:-2700s}
```

#### wipe namespace

```sh
#wipe clean
kubectl delete ns ${NS}

rm -rf ${FOLDER_NAME}

```


#### prep NS

1. create folders and namespaces

    ```bash
    mkdir -p ~/project
    mkdir -p ${FOLDER_NAME}
    mkdir -p ${FOLDER_NAME}/site-config

    tee  ${FOLDER_NAME}/namespace.yaml > /dev/null << EOF
    ---
    apiVersion: v1
    kind: Namespace
    metadata:
      name: ${NS}
      labels:
        name: "${NS}_namespace"
    EOF

    kubectl apply -f ${FOLDER_NAME}/namespace.yaml

    kubectl get ns

    ```

#### ldap

1. gelldap and gelmail

    ```bash

    cd ~/project/
    git clone https://gelgitlab.race.sas.com/GEL/utilities/gelldap.git
    cd ~/project/gelldap/
    git fetch --all
    GELLDAP_BRANCH=int_images
    git reset --hard origin/${GELLDAP_BRANCH}

    cd ~/project/gelldap/
    kustomize build ./no_TLS/ | kubectl -n ${NS} apply -f -

    cp ~/project/gelldap/no_TLS/gelldap-sitedefault.yaml \
           ${FOLDER_NAME}/site-config/

    ```

#### Choose order

1. copy order stuff

    ```bash


    ORDER_FILE=$(ls ~/orders/ \
        | grep ${ORDER} \
        | grep ${CADENCE_NAME} \
        | grep ${CADENCE_VERSION} \
        | sort \
        | tail -n 1 \
        )

    echo $ORDER_FILE

    cp ~/orders/${ORDER_FILE} ${FOLDER_NAME}/
    cd  ${FOLDER_NAME}/

    rm -rf ./sas-bases/
    tar xf ${ORDER_FILE}

    ```


#### Daily update-checker run

1. create a transformer to run this very often:

    ```bash

    bash -c "cat << EOF > ${FOLDER_NAME}/site-config/daily_update_check.yaml
    apiVersion: builtin
    kind: PatchTransformer
    metadata:
      name: daily-update-check
    patch: |-
      - op: replace
        path: /spec/schedule
        value: '00,15,30,45 * * * *'
      - op: replace
        path: /spec/successfulJobsHistoryLimit
        value: 24
    target:
      name: sas-update-checker
      kind: CronJob
    EOF"

    ```

#### MPP CAS:

1. MPP CAS with secondary controller

    ```bash
    bash -c "cat << EOF > ${FOLDER_NAME}/site-config/cas-default_secondary_controller.yaml
    ---
    apiVersion: builtin
    kind: PatchTransformer
    metadata:
      name: cas-add-backup-default
    patch: |-
       - op: replace
         path: /spec/backupControllers
         value:
           1
    target:
      group: viya.sas.com
      kind: CASDeployment
      labelSelector: "sas.com/cas-server-default"
      version: v1alpha1
    EOF"

    bash -c "cat << EOF > ${FOLDER_NAME}/site-config/cas-default_workers.yaml
    ---
    apiVersion: builtin
    kind: PatchTransformer
    metadata:
      name: cas-add-workers-default
    patch: |-
       - op: replace
         path: /spec/workers
         value:
           4
    target:
      group: viya.sas.com
      kind: CASDeployment
      labelSelector: "sas.com/cas-server-default"
      version: v1alpha1
    EOF"

    ```

#### Crunchy postgres needs a special file

1. so the postgres readme states:

    ```bash

    mkdir -p ${FOLDER_NAME}/site-config/postgres

    cat ${FOLDER_NAME}/sas-bases/examples/configure-postgres/internal/custom-config/postgres-custom-config.yaml | \
        sed 's|\-\ {{\ HBA\-CONF\-HOST\-OR\-HOSTSSL\ }}|- hostssl|g' | \
        sed 's|\ {{\ PASSWORD\-ENCRYPTION\ }}| scram-sha-256|g' | \
        sed 's|scram-sha-256 should|{{\ PASSWORD\-ENCRYPTION\ }}\ should|g' | \
        sed 's|scram-sha-256 # Added|scram-sha-256             # Added|g' | \
        sed 's|max_wal_size: 2GB|max_wal_size: 1GB|g' | \
        sed 's|wal_keep_segments: 1000|wal_keep_segments: 512 |g' \
        > ${FOLDER_NAME}/site-config/postgres/postgres-custom-config.yaml

    ```

#### TLS work

* from Stuart

    ```bash
    mkdir -p ${FOLDER_NAME}/site-config/security/cacerts
    mkdir -p ${FOLDER_NAME}/site-config/security/cert-manager-issuer

    # Download Intermediate CA cert and key
    curl -sk https://gelgitlab.race.sas.com/GEL/workshops/PSGEL263-sas-viya-4.0.1-advanced-topics-in-authentication/-/raw/master/scripts/TLS/GELEnvRootCA/intermediate.cert.pem \
    -o ${FOLDER_NAME}/site-config/security/cacerts/intermediate.cert.pem
    curl -sk https://gelgitlab.race.sas.com/GEL/workshops/PSGEL263-sas-viya-4.0.1-advanced-topics-in-authentication/-/raw/master/scripts/TLS/GELEnvRootCA/intermediate.key.pem \
    -o ${FOLDER_NAME}/site-config/security/cacerts/intermediate.key.pem

    # Download CA cert
    curl -sk https://gelgitlab.race.sas.com/GEL/workshops/PSGEL263-sas-viya-4.0.1-advanced-topics-in-authentication/-/raw/master/scripts/TLS/GELEnvRootCA/ca_cert.pem \
    -o ${FOLDER_NAME}/site-config/security/cacerts/ca_cert.pem


    # Create Ingress YAML
    tee ${FOLDER_NAME}/site-config/security/cert-manager-provided-ingress-certificate.yaml > /dev/null <<EOF
    ---
    apiVersion: builtin
    kind: PatchTransformer
    metadata:
      name: sas-cert-manager-ingress-annotation-transformer
    patch: |-
      - op: add
        path: /metadata/annotations/cert-manager.io~1issuer
        value: sas-viya-issuer
    target:
      kind: Ingress
      name: .*
    EOF

    # Create Issuer YAML files
    tee ${FOLDER_NAME}/site-config/security/cert-manager-issuer/kustomization.yaml > /dev/null <<EOF
    resources:
    - resources.yaml
    EOF

    export BASE64_CA=`cat ${FOLDER_NAME}/site-config/security/cacerts/ca_cert.pem|base64|tr -d '\n'`
    export BASE64_CERT=`cat ${FOLDER_NAME}/site-config/security/cacerts/intermediate.cert.pem|base64|tr -d '\n'`
    export BASE64_KEY=`cat ${FOLDER_NAME}/site-config/security/cacerts/intermediate.key.pem|base64|tr -d '\n'`

    tee ${FOLDER_NAME}/site-config/security/cert-manager-issuer/resources.yaml > /dev/null <<EOF
    ---
    # sas-viya-ca-certificate.yaml
    # ............................
    apiVersion: v1
    kind: Secret
    metadata:
      name: sas-viya-ca-certificate-secret
    data:
      ca.crt: $BASE64_CA
      tls.crt: $BASE64_CERT
      tls.key: $BASE64_KEY
    ---
    # sas-viya-issuer.yaml
    # ....................
    apiVersion: cert-manager.io/v1alpha2
    kind: Issuer
    metadata:
      name: sas-viya-issuer
    spec:
      ca:
        secretName: sas-viya-ca-certificate-secret
    EOF



    ```

#### Kustomization

1. create kustomization.yaml

    ```bash

    INGRESS_SUFFIX=$(hostname -f)
    echo $INGRESS_SUFFIX

    cd ${FOLDER_NAME}
    #rm ./gelldap
    #ln -s ~/project/gelldap ./gelldap

    bash -c "cat << EOF > ${FOLDER_NAME}/kustomization.yaml.tls
    ---
    namespace: ${NS}
    resources:
      - sas-bases/base
      #- sas-bases/overlays/cert-manager-issuer     # TLS
      - site-config/security/cert-manager-issuer
      - sas-bases/overlays/network/ingress
      - sas-bases/overlays/network/ingress/security   # TLS
      - sas-bases/overlays/internal-postgres
      - sas-bases/overlays/crunchydata
      - sas-bases/overlays/cas-server
      - sas-bases/overlays/update-checker       # added update checker
      #- gelldap/no_TLS
      #- sas-bases/overlays/cas-server/auto-resources    # CAS-related
    ## added in .0.6
    configurations:
      - sas-bases/overlays/required/kustomizeconfig.yaml
    transformers:
      - sas-bases/overlays/network/ingress/security/transformers/product-tls-transformers.yaml   # TLS
      - sas-bases/overlays/network/ingress/security/transformers/ingress-tls-transformers.yaml   # TLS
      - sas-bases/overlays/network/ingress/security/transformers/backend-tls-transformers.yaml   # TLS
      - sas-bases/overlays/required/transformers.yaml
      - sas-bases/overlays/internal-postgres/internal-postgres-transformer.yaml
      - site-config/security/cert-manager-provided-ingress-certificate.yaml     # TLS
      - site-config/daily_update_check.yaml      # change the frequency of the update-check
      #- sas-bases/overlays/cas-server/auto-resources/remove-resources.yaml    # CAS-related
      - site-config/cas-default_secondary_controller.yaml
      - site-config/cas-default_workers.yaml
      #- sas-bases/overlays/scaling/zero-scale/phase-0-transformer.yaml
      #- sas-bases/overlays/scaling/zero-scale/phase-1-transformer.yaml
    generators:
      - site-config/postgres/postgres-custom-config.yaml
    configMapGenerator:
      - name: ingress-input
        behavior: merge
        literals:
          - INGRESS_HOST=${INGRESS_PREFIX}.${INGRESS_SUFFIX}
      - name: sas-shared-config
        behavior: merge
        literals:
          - SAS_SERVICES_URL=https://${INGRESS_PREFIX}.${INGRESS_SUFFIX}
      - name: sas-consul-config            ## This injects content into consul. You can add, but not replace
        behavior: merge
        files:
          - SITEDEFAULT_CONF=site-config/gelldap-sitedefault.yaml
    EOF"


    bash -c "cat << EOF > ${FOLDER_NAME}/kustomization.yaml.notls
    ---
    namespace: ${NS}
    resources:
      - sas-bases/base
      - sas-bases/overlays/network/ingress
      - sas-bases/overlays/internal-postgres
      - sas-bases/overlays/crunchydata
      - sas-bases/overlays/cas-server
      - sas-bases/overlays/update-checker       # added update checker
      #- gelldap/no_TLS
      #- sas-bases/overlays/cas-server/auto-resources    # CAS-related
    ## added in .0.6
    configurations:
      - sas-bases/overlays/required/kustomizeconfig.yaml
    transformers:
      - sas-bases/overlays/required/transformers.yaml
      - sas-bases/overlays/internal-postgres/internal-postgres-transformer.yaml
      - site-config/daily_update_check.yaml      # change the frequency of the update-check
      #- sas-bases/overlays/cas-server/auto-resources/remove-resources.yaml    # CAS-related
      - site-config/cas-default_secondary_controller.yaml
      - site-config/cas-default_workers.yaml
      #- sas-bases/overlays/scaling/zero-scale/phase-0-transformer.yaml
      #- sas-bases/overlays/scaling/zero-scale/phase-1-transformer.yaml
    configMapGenerator:
      - name: ingress-input
        behavior: merge
        literals:
          - INGRESS_HOST=${INGRESS_PREFIX}.${INGRESS_SUFFIX}
      - name: sas-shared-config
        behavior: merge
        literals:
          - SAS_SERVICES_URL=http://${INGRESS_PREFIX}.${INGRESS_SUFFIX}
      - name: sas-consul-config            ## This injects content into consul. You can add, but not replace
        behavior: merge
        files:
          - SITEDEFAULT_CONF=site-config/gelldap-sitedefault.yaml
    EOF"

    ```

#### build

1. build

    ```bash

    cd  ${FOLDER_NAME}/

    rm -f kustomization.yaml
    #ln -s kustomization.yaml.notls kustomization.yaml
    #time kustomize build -o site.yaml.notls

    rm -f kustomization.yaml
    ln -s kustomization.yaml.tls kustomization.yaml
    time kustomize build -o site.yaml.tls

    ## choose which one we want
    rm -f site.yaml
    ln -s site.yaml.tls site.yaml
    ```

#### apply

1. apply

    ```bash

    #kubectl  -n ${NS}  apply   --selector="sas.com/admin=cluster-wide" -f site.yaml
    #time kubectl wait  --for condition=established --timeout=60s -l "sas.com/admin=cluster-wide" crd
    #kubectl  -n ${NS} apply  --selector="sas.com/admin=cluster-local" -f site.yaml --prune
    #kubectl  -n ${NS} apply  --selector="sas.com/admin=namespace" -f site.yaml --prune

    # kubectl  -n ${NS} apply -f site.yaml

    ```

#### Urls

1. Urls

    ```bash
    printf "\n* [Viya Drive (${NS}) URL (HTTP**S**)](https://${INGRESS_PREFIX}.$(hostname -f)/SASDrive )\n\n" | tee -a /home/cloud-user/urls.md
    printf "\n* [Viya Environment Manager (${NS}) URL (HTTP**S**)](https://${INGRESS_PREFIX}.$(hostname -f)/SASEnvironmentManager )\n\n" | tee -a /home/cloud-user/urls.md
    ```

#### Do one with HA-enabled

* HA stuff

    ```bash
    ## all you need to do to apply the variation is:
    mkdir -p ~/project/deploy/${NS}_HA/
    sudo chmod -R 777 ~/project/deploy/${NS}_HA/

    ## copy the HA transformer
    cp ~/project/deploy/${NS}/sas-bases/overlays/scaling/ha/enable-ha-transformer.yaml \
        ~/project/deploy/${NS}_HA/
    sudo chmod 777 ~/project/deploy/${NS}_HA/enable-ha-transformer.yaml

    bash -c "cat << EOF > ~/project/deploy/${NS}_HA/kustomization.yaml
    ---
    resources:
      - ../${NS}/        ## get same content as ${NS}
    transformers:
      - enable-ha-transformer.yaml
    EOF"

    cd ~/project/deploy/${NS}_HA/
    time kustomize build -o site.yaml


    cd ~/project/deploy/${NS}_HA/

    #kubectl  -n ${NS} wait \
    #        --for=condition=ready \
    #        pod --selector='app.kubernetes.io/name=sas-readiness' \
    #        --timeout=${READINESS_TIMEOUT}

    #kubectl  -n ${NS}  apply   --selector="sas.com/admin=cluster-wide" -f site.yaml
    #time kubectl wait  --for condition=established --timeout=60s -l "sas.com/admin=cluster-wide" crd
    #kubectl  -n ${NS} apply  --selector="sas.com/admin=cluster-local" -f site.yaml --prune
    #kubectl  -n ${NS} apply  --selector="sas.com/admin=namespace" -f site.yaml --prune

    ```

### CADENCE: Stable

#### default values for variables

```bash
NS=gelenv-stable
CADENCE_NAME='stable'
CADENCE_VERSION='2020.1.5'
ORDER=9CHTZV
INGRESS_PREFIX=${NS}
FOLDER_NAME=~/project/deploy/${NS}
```

#### wipe namespace

```sh
#wipe clean
kubectl delete ns ${NS}

rm -rf ${FOLDER_NAME}

```

#### prep namespace

1. create folders and namespaces

    ```bash
    mkdir -p ~/project
    mkdir -p ${FOLDER_NAME}
    mkdir -p ${FOLDER_NAME}/site-config

    tee  ${FOLDER_NAME}/namespace.yaml > /dev/null << EOF
    ---
    apiVersion: v1
    kind: Namespace
    metadata:
      name: ${NS}
      labels:
        name: "${NS}_namespace"
    EOF

    kubectl apply -f ${FOLDER_NAME}/namespace.yaml

    kubectl get ns

    ```

#### ldap

1. gelldap and gelmail

    ```bash

    cd ~/project/
    git clone https://gelgitlab.race.sas.com/GEL/utilities/gelldap.git
    cd ~/project/gelldap/
    git fetch --all
    GELLDAP_BRANCH=int_images
    git reset --hard origin/${GELLDAP_BRANCH}

    cd ~/project/gelldap/
    kustomize build ./no_TLS/ | kubectl -n ${NS} apply -f -

    cp ~/project/gelldap/no_TLS/gelldap-sitedefault.yaml \
           ${FOLDER_NAME}/site-config/

    ```

#### get order

1. copy order stuff

    ```bash


    ORDER_FILE=$(ls ~/orders/ \
        | grep ${ORDER} \
        | grep ${CADENCE_NAME} \
        | grep ${CADENCE_VERSION} \
        | sort \
        | tail -n 1 \
        )

    #SASViyaV4_9CDZDD_0_stable_2020.0.4_20200821.1598037827526_deploymentAssets_2020-08-24T165225
    echo $ORDER_FILE

    cp ~/orders/${ORDER_FILE} ${FOLDER_NAME}/
    cd  ${FOLDER_NAME}/

    rm -rf ./sas-bases/
    tar xf ${ORDER_FILE}

    ```

<!--
1. override with mirrored order:

    ```sh
    rm -rf ./sas-bases/
    rm -rf *.tgz

    echo "09RG3K" > ~/dailymirror.txt

    curl https://gelweb.race.sas.com/scripts/PSGEL255/orders/$(cat ~/dailymirror.txt).kustomize.tgz \
        -o ${FOLDER_NAME}/dailymirror.tgz

    cd  ${FOLDER_NAME}/

    tar xf dailymirror.tgz

    ```
 -->


#### Daily update-checker run

1. create a transformer to run this very often:

    ```bash

    bash -c "cat << EOF > ${FOLDER_NAME}/site-config/daily_update_check.yaml
    apiVersion: builtin
    kind: PatchTransformer
    metadata:
      name: daily-update-check
    patch: |-
      - op: replace
        path: /spec/schedule
        value: '00,15,30,45 * * * *'
      - op: replace
        path: /spec/successfulJobsHistoryLimit
        value: 24
    target:
      name: sas-update-checker
      kind: CronJob
    EOF"

    ```

#### MPP CAS:

1. MPP CAS with secondary controller

    ```bash
    bash -c "cat << EOF > ${FOLDER_NAME}/site-config/cas-default_secondary_controller.yaml
    ---
    apiVersion: builtin
    kind: PatchTransformer
    metadata:
      name: cas-add-backup-default
    patch: |-
       - op: replace
         path: /spec/backupControllers
         value:
           1
    target:
      group: viya.sas.com
      kind: CASDeployment
      labelSelector: "sas.com/cas-server-default"
      version: v1alpha1
    EOF"

    bash -c "cat << EOF > ${FOLDER_NAME}/site-config/cas-default_workers.yaml
    ---
    apiVersion: builtin
    kind: PatchTransformer
    metadata:
      name: cas-add-workers-default
    patch: |-
       - op: replace
         path: /spec/workers
         value:
           4
    target:
      group: viya.sas.com
      kind: CASDeployment
      labelSelector: "sas.com/cas-server-default"
      version: v1alpha1
    EOF"

    ```

#### Crunchy postgres needs a special file

1. so the postgres readme states:

    ```bash

    mkdir -p ${FOLDER_NAME}/site-config/postgres
    #cp ${FOLDER_NAME}/sas-bases/examples/configure-postgres/internal/custom-config/postgres-custom-config.yaml \
    #    ${FOLDER_NAME}/site-config/postgres/postgres-custom-config.yaml

    cat ${FOLDER_NAME}/sas-bases/examples/configure-postgres/internal/custom-config/postgres-custom-config.yaml | \
        sed 's|\-\ {{\ HBA\-CONF\-HOST\-OR\-HOSTSSL\ }}|- hostssl|g' | \
        sed 's|\ {{\ PASSWORD\-ENCRYPTION\ }}| scram-sha-256|g' | \
        sed 's|scram-sha-256 should|{{\ PASSWORD\-ENCRYPTION\ }}\ should|g' | \
        sed 's|scram-sha-256 # Added|scram-sha-256             # Added|g' | \
        sed 's|max_wal_size: 2GB|max_wal_size: 1GB|g' | \
        sed 's|wal_keep_segments: 1000|wal_keep_segments: 512 |g' \
        > ${FOLDER_NAME}/site-config/postgres/postgres-custom-config.yaml

    ```

#### TLS work

* from Stuart

    ```bash
    mkdir -p ${FOLDER_NAME}/site-config/security/cacerts
    mkdir -p ${FOLDER_NAME}/site-config/security/cert-manager-issuer

    # Download Intermediate CA cert and key
    curl -sk https://gelgitlab.race.sas.com/GEL/workshops/PSGEL263-sas-viya-4.0.1-advanced-topics-in-authentication/-/raw/master/scripts/TLS/GELEnvRootCA/intermediate.cert.pem \
    -o ${FOLDER_NAME}/site-config/security/cacerts/intermediate.cert.pem
    curl -sk https://gelgitlab.race.sas.com/GEL/workshops/PSGEL263-sas-viya-4.0.1-advanced-topics-in-authentication/-/raw/master/scripts/TLS/GELEnvRootCA/intermediate.key.pem \
    -o ${FOLDER_NAME}/site-config/security/cacerts/intermediate.key.pem

    # Download CA cert
    curl -sk https://gelgitlab.race.sas.com/GEL/workshops/PSGEL263-sas-viya-4.0.1-advanced-topics-in-authentication/-/raw/master/scripts/TLS/GELEnvRootCA/ca_cert.pem \
    -o ${FOLDER_NAME}/site-config/security/cacerts/ca_cert.pem


    # Create Ingress YAML
    tee ${FOLDER_NAME}/site-config/security/cert-manager-provided-ingress-certificate.yaml > /dev/null <<EOF
    ---
    apiVersion: builtin
    kind: PatchTransformer
    metadata:
      name: sas-cert-manager-ingress-annotation-transformer
    patch: |-
      - op: add
        path: /metadata/annotations/cert-manager.io~1issuer
        value: sas-viya-issuer
    target:
      kind: Ingress
      name: .*
    EOF

    # Create Issuer YAML files
    tee ${FOLDER_NAME}/site-config/security/cert-manager-issuer/kustomization.yaml > /dev/null <<EOF
    resources:
    - resources.yaml
    EOF

    export BASE64_CA=`cat ${FOLDER_NAME}/site-config/security/cacerts/ca_cert.pem|base64|tr -d '\n'`
    export BASE64_CERT=`cat ${FOLDER_NAME}/site-config/security/cacerts/intermediate.cert.pem|base64|tr -d '\n'`
    export BASE64_KEY=`cat ${FOLDER_NAME}/site-config/security/cacerts/intermediate.key.pem|base64|tr -d '\n'`

    tee ${FOLDER_NAME}/site-config/security/cert-manager-issuer/resources.yaml > /dev/null <<EOF
    ---
    # sas-viya-ca-certificate.yaml
    # ............................
    apiVersion: v1
    kind: Secret
    metadata:
      name: sas-viya-ca-certificate-secret
    data:
      ca.crt: $BASE64_CA
      tls.crt: $BASE64_CERT
      tls.key: $BASE64_KEY
    ---
    # sas-viya-issuer.yaml
    # ....................
    apiVersion: cert-manager.io/v1alpha2
    kind: Issuer
    metadata:
      name: sas-viya-issuer
    spec:
      ca:
        secretName: sas-viya-ca-certificate-secret
    EOF

    ```

#### Kustomization

1. create kustomization.yaml

    ```bash

    INGRESS_SUFFIX=$(hostname -f)
    echo $INGRESS_SUFFIX

    cd ${FOLDER_NAME}
    #rm ./gelldap
    #ln -s ~/project/gelldap ./gelldap

    bash -c "cat << EOF > ${FOLDER_NAME}/kustomization.yaml.tls
    ---
    namespace: ${NS}
    resources:
      - sas-bases/base
      #- sas-bases/overlays/cert-manager-issuer     # TLS
      - site-config/security/cert-manager-issuer
      - sas-bases/overlays/network/ingress
      - sas-bases/overlays/network/ingress/security   # TLS
      - sas-bases/overlays/internal-postgres
      - sas-bases/overlays/crunchydata
      - sas-bases/overlays/internal-elasticsearch   # Stable 2020.1.3
      - sas-bases/overlays/cas-server
      - sas-bases/overlays/update-checker       # added update checker
      #- gelldap/no_TLS
      #- sas-bases/overlays/cas-server/auto-resources    # CAS-related
    ## added in .0.6
    configurations:
      - sas-bases/overlays/required/kustomizeconfig.yaml
    transformers:
      - sas-bases/overlays/network/ingress/security/transformers/product-tls-transformers.yaml   # TLS
      - sas-bases/overlays/network/ingress/security/transformers/ingress-tls-transformers.yaml   # TLS
      - sas-bases/overlays/network/ingress/security/transformers/backend-tls-transformers.yaml   # TLS
      - sas-bases/overlays/internal-elasticsearch/sysctl-transformer.yaml                    # Stable 2020.1.3
      - sas-bases/overlays/required/transformers.yaml
      - sas-bases/overlays/internal-postgres/internal-postgres-transformer.yaml
      - site-config/security/cert-manager-provided-ingress-certificate.yaml     # TLS
      - site-config/daily_update_check.yaml      # change the frequency of the update-check
      #- sas-bases/overlays/cas-server/auto-resources/remove-resources.yaml    # CAS-related
      - sas-bases/overlays/internal-elasticsearch/internal-elasticsearch-transformer.yaml    # Stable 2020.1.3
      - site-config/cas-default_secondary_controller.yaml
      - site-config/cas-default_workers.yaml
      #- sas-bases/overlays/scaling/zero-scale/phase-0-transformer.yaml
      #- sas-bases/overlays/scaling/zero-scale/phase-1-transformer.yaml
    generators:
      - site-config/postgres/postgres-custom-config.yaml
    configMapGenerator:
      - name: ingress-input
        behavior: merge
        literals:
          - INGRESS_HOST=${INGRESS_PREFIX}.${INGRESS_SUFFIX}
      - name: sas-shared-config
        behavior: merge
        literals:
          - SAS_SERVICES_URL=https://${INGRESS_PREFIX}.${INGRESS_SUFFIX}
      - name: sas-consul-config            ## This injects content into consul. You can add, but not replace
        behavior: merge
        files:
          - SITEDEFAULT_CONF=site-config/gelldap-sitedefault.yaml
      # # This is to fix an issue that only appears in RACE Exnet.
      # # Do not do this at a customer site
      - name: sas-go-config
        behavior: merge
        literals:
          - SAS_BOOTSTRAP_HTTP_CLIENT_TIMEOUT_REQUEST='5m'
    EOF"


    bash -c "cat << EOF > ${FOLDER_NAME}/kustomization.yaml.notls
    ---
    namespace: ${NS}
    resources:
      - sas-bases/base
      - sas-bases/overlays/network/ingress
      - sas-bases/overlays/internal-postgres
      - sas-bases/overlays/crunchydata
      - sas-bases/overlays/cas-server
      - sas-bases/overlays/update-checker       # added update checker
      #- gelldap/no_TLS
      #- sas-bases/overlays/cas-server/auto-resources    # CAS-related
    ## added in .0.6
    configurations:
      - sas-bases/overlays/required/kustomizeconfig.yaml
    transformers:
      - sas-bases/overlays/required/transformers.yaml
      - sas-bases/overlays/internal-postgres/internal-postgres-transformer.yaml
      - site-config/daily_update_check.yaml      # change the frequency of the update-check
      #- sas-bases/overlays/cas-server/auto-resources/remove-resources.yaml    # CAS-related
      - site-config/cas-default_secondary_controller.yaml
      - site-config/cas-default_workers.yaml
      #- sas-bases/overlays/scaling/zero-scale/phase-0-transformer.yaml
      #- sas-bases/overlays/scaling/zero-scale/phase-1-transformer.yaml
    configMapGenerator:
      - name: ingress-input
        behavior: merge
        literals:
          - INGRESS_HOST=${INGRESS_PREFIX}.${INGRESS_SUFFIX}
      - name: sas-shared-config
        behavior: merge
        literals:
          - SAS_SERVICES_URL=http://${INGRESS_PREFIX}.${INGRESS_SUFFIX}
      - name: sas-consul-config            ## This injects content into consul. You can add, but not replace
        behavior: merge
        files:
          - SITEDEFAULT_CONF=site-config/gelldap-sitedefault.yaml
      # # This is to fix an issue that only appears in RACE Exnet.
      # # Do not do this at a customer site
      - name: sas-go-config
        behavior: merge
        literals:
          - SAS_BOOTSTRAP_HTTP_CLIENT_TIMEOUT_REQUEST='5m'
    EOF"
    ```

#### build

1. build

    ```bash

    cd  ${FOLDER_NAME}/

    rm -f kustomization.yaml
    #ln -s kustomization.yaml.notls kustomization.yaml
    #time kustomize build -o site.yaml.notls

    rm -f kustomization.yaml
    ln -s kustomization.yaml.tls kustomization.yaml
    time kustomize build -o site.yaml.tls

    ## choose which one we want
    rm -f site.yaml
    ln -s site.yaml.tls site.yaml
    ```

#### apply

1. apply

    ```bash
    cd  ${FOLDER_NAME}/
    #kubectl  -n ${NS}  apply   --selector="sas.com/admin=cluster-wide" -f site.yaml                    | tee /tmp/site_apply1.log
    #time kubectl wait  --for condition=established --timeout=60s -l "sas.com/admin=cluster-wide" crd   | tee /tmp/site_wait.log
    #kubectl  -n ${NS} apply  --selector="sas.com/admin=cluster-local" -f site.yaml --prune             | tee /tmp/site_apply2.log
    #kubectl  -n ${NS} apply  --selector="sas.com/admin=namespace" -f site.yaml --prune                 | tee /tmp/site_apply3.log

    # kubectl  -n ${NS} apply -f site.yaml

    ```

#### Urls

1. Urls

    ```bash
    #printf "\n* [Viya Drive (${NS}) URL (HTTP )](http://${INGRESS_PREFIX}.$(hostname -f)/SASDrive )\n\n" | tee -a /home/cloud-user/urls.md
    printf "\n* [Viya Drive (${NS}) URL (HTTP**S**)](https://${INGRESS_PREFIX}.$(hostname -f)/SASDrive )\n\n" | tee -a /home/cloud-user/urls.md
    #printf "\n* [Viya Environment Manager (${NS}) URL (HTTP)](http://${INGRESS_PREFIX}.$(hostname -f)/SASEnvironmentManager )\n\n" | tee -a /home/cloud-user/urls.md
    printf "\n* [Viya Environment Manager (${NS}) URL (HTTP**S**)](https://${INGRESS_PREFIX}.$(hostname -f)/SASEnvironmentManager )\n\n" | tee -a /home/cloud-user/urls.md
    ```

#### Do one with HA-enabled

* HA stuff

    ```bash
    ## all you need to do to apply the variation is:
    mkdir -p ~/project/deploy/${NS}_HA/

    ## copy the HA transformer
    cp ~/project/deploy/${NS}/sas-bases/overlays/scaling/ha/enable-ha-transformer.yaml \
        ~/project/deploy/${NS}_HA/
        sudo chmod 777 ~/project/deploy/${NS}_HA/enable-ha-transformer.yaml


    bash -c "cat << EOF > ~/project/deploy/${NS}_HA/kustomization.yaml
    ---
    resources:
      - ../${NS}/        ## get same content as ${NS}
    transformers:
      - enable-ha-transformer.yaml
    EOF"

    cd ~/project/deploy/${NS}_HA/
    time kustomize build -o site.yaml

    #time kubectl wait -n ${NS} \
    #    --for=condition=ready pod \
    #    --selector='app.kubernetes.io/name=sas-readiness'  \
    #    --timeout=${READINESS_TIMEOUT}

    cd ~/project/deploy/${NS}_HA/

    #kubectl apply -f  ~/project/deploy/${NS}_HA/site.yaml
    #kubectl  -n ${NS}  apply   --selector="sas.com/admin=cluster-wide" -f site.yaml                    | tee /tmp/site_apply1.log
    #time kubectl wait  --for condition=established --timeout=60s -l "sas.com/admin=cluster-wide" crd   | tee /tmp/site_wait.log
    #kubectl  -n ${NS} apply  --selector="sas.com/admin=cluster-local" -f site.yaml --prune             | tee /tmp/site_apply2.log
    #kubectl  -n ${NS} apply  --selector="sas.com/admin=namespace" -f site.yaml --prune                 | tee /tmp/site_apply3.log

    ```

## IF_END for Shared Collection

1. end the if

    ```bash

    fi
    ```

## IF_BEGIN for 5-machine-collection

1. begin the if

    ```bash
    source <( cat /opt/raceutils/.bootstrap.txt  )
    source <( cat /opt/raceutils/.id.txt  )

    if  [ "$collection_size" -le "9"  ] && [ "$collection_size" -ge "3"  ] ; then
    ```

### Labels and taints

* clear it all up

    ```bash
    kubectl label nodes \
        intnode01 intnode02 intnode03 intnode04 intnode05   \
        workload.sas.com/class-          --overwrite
    kubectl taint nodes \
        intnode01 intnode02 intnode03 intnode04 intnode05   \
        workload.sas.com/class-          --overwrite
    ```

* start with labels

    ```bash
    #kubectl label nodes \
    #    intnode01   \
    #    workload.sas.com/class=connect          --overwrite
    kubectl label nodes \
         intnode01   \
        workload.sas.com/class=compute          --overwrite
    kubectl label nodes \
         intnode02    \
         intnode03    \
        workload.sas.com/class=stateful          --overwrite
    kubectl label nodes \
        intnode04   \
        intnode05   \
        workload.sas.com/class=stateless          --overwrite
    #kubectl label nodes \
    #   intnode05    \
    #    workload.sas.com/class=cas          --overwrite

    ```

* no taints yet

### CADENCE: LTS

#### default values for variables

```bash
    NS=gelenv
    CADENCE_NAME='lts'
    CADENCE_VERSION='2020.1'
    ORDER=${ORDER:-9CDZDD}
    INGRESS_PREFIX=${NS}
    FOLDER_NAME=~/project/deploy/${NS}-${CADENCE_NAME}
    READINESS_TIMEOUT=5s
```

#### prep NS

1. create folders and namespaces

    ```bash
    mkdir -p ~/project
    mkdir -p ${FOLDER_NAME}
    mkdir -p ${FOLDER_NAME}/site-config

    tee  ${FOLDER_NAME}/namespace.yaml > /dev/null << EOF
    ---
    apiVersion: v1
    kind: Namespace
    metadata:
      name: ${NS}
      labels:
        name: "${NS}_namespace"
    EOF

    kubectl apply -f ${FOLDER_NAME}/namespace.yaml

    kubectl get ns

    ```

#### ldap

1. gelldap and gelmail

    ```bash

    cd ~/project/
    git clone https://gelgitlab.race.sas.com/GEL/utilities/gelldap.git
    cd ~/project/gelldap/
    git fetch --all
    GELLDAP_BRANCH=int_images
    git reset --hard origin/${GELLDAP_BRANCH}

    cd ~/project/gelldap/
    kustomize build ./no_TLS/ | kubectl -n ${NS} apply -f -

    cp ~/project/gelldap/no_TLS/gelldap-sitedefault.yaml \
           ${FOLDER_NAME}/site-config/

    ```

#### Choose order

1. copy order stuff

    ```bash


    ORDER_FILE=$(ls ~/orders/ \
        | grep ${ORDER} \
        | grep ${CADENCE_NAME} \
        | grep ${CADENCE_VERSION} \
        | sort \
        | tail -n 1 \
        )

    #SASViyaV4_9CDZDD_0_stable_2020.0.4_20200821.1598037827526_deploymentAssets_2020-08-24T165225
    echo $ORDER_FILE

    cp ~/orders/${ORDER_FILE} ${FOLDER_NAME}/
    cd  ${FOLDER_NAME}/

    rm -rf ./sas-bases/
    tar xf ${ORDER_FILE}

    ```


#### Daily update-checker run

1. create a transformer to run this very often:

    ```bash

    bash -c "cat << EOF > ${FOLDER_NAME}/site-config/daily_update_check.yaml
    apiVersion: builtin
    kind: PatchTransformer
    metadata:
      name: daily-update-check
    patch: |-
      - op: replace
        path: /spec/schedule
        value: '00,15,30,45 * * * *'
      - op: replace
        path: /spec/successfulJobsHistoryLimit
        value: 24
    target:
      name: sas-update-checker
      kind: CronJob
    EOF"

    ```

#### MPP CAS:

1. MPP CAS with secondary controller

    ```bash
    bash -c "cat << EOF > ${FOLDER_NAME}/site-config/cas-default_secondary_controller.yaml
    ---
    apiVersion: builtin
    kind: PatchTransformer
    metadata:
      name: cas-add-backup-default
    patch: |-
       - op: replace
         path: /spec/backupControllers
         value:
           1
    target:
      group: viya.sas.com
      kind: CASDeployment
      labelSelector: "sas.com/cas-server-default"
      version: v1alpha1
    EOF"

    bash -c "cat << EOF > ${FOLDER_NAME}/site-config/cas-default_workers.yaml
    ---
    apiVersion: builtin
    kind: PatchTransformer
    metadata:
      name: cas-add-workers-default
    patch: |-
       - op: replace
         path: /spec/workers
         value:
           4
    target:
      group: viya.sas.com
      kind: CASDeployment
      labelSelector: "sas.com/cas-server-default"
      version: v1alpha1
    EOF"

    ```

#### Crunchy postgres needs a special file

1. so the postgres readme states:

    ```bash

    mkdir -p ${FOLDER_NAME}/site-config/postgres
    #cp ${FOLDER_NAME}/sas-bases/examples/configure-postgres/internal/custom-config/postgres-custom-config.yaml \
    #    ${FOLDER_NAME}/site-config/postgres/postgres-custom-config.yaml

    cat ${FOLDER_NAME}/sas-bases/examples/configure-postgres/internal/custom-config/postgres-custom-config.yaml | \
        sed 's|\-\ {{\ HBA\-CONF\-HOST\-OR\-HOSTSSL\ }}|- hostssl|g' | \
        sed 's|\ {{\ PASSWORD\-ENCRYPTION\ }}| scram-sha-256|g' | \
        sed 's|scram-sha-256 should|{{\ PASSWORD\-ENCRYPTION\ }}\ should|g' | \
        sed 's|scram-sha-256 # Added|scram-sha-256             # Added|g' | \
        sed 's|max_wal_size: 2GB|max_wal_size: 1GB|g' | \
        sed 's|wal_keep_segments: 1000|wal_keep_segments: 512 |g' \
        > ${FOLDER_NAME}/site-config/postgres/postgres-custom-config.yaml

    ```

#### TLS work

* from Stuart

    ```bash
    mkdir -p ${FOLDER_NAME}/site-config/security/cacerts
    mkdir -p ${FOLDER_NAME}/site-config/security/cert-manager-issuer

    # Download Intermediate CA cert and key
    curl -sk https://gelgitlab.race.sas.com/GEL/workshops/PSGEL263-sas-viya-4.0.1-advanced-topics-in-authentication/-/raw/master/scripts/TLS/GELEnvRootCA/intermediate.cert.pem \
    -o ${FOLDER_NAME}/site-config/security/cacerts/intermediate.cert.pem
    curl -sk https://gelgitlab.race.sas.com/GEL/workshops/PSGEL263-sas-viya-4.0.1-advanced-topics-in-authentication/-/raw/master/scripts/TLS/GELEnvRootCA/intermediate.key.pem \
    -o ${FOLDER_NAME}/site-config/security/cacerts/intermediate.key.pem

    # Download CA cert
    curl -sk https://gelgitlab.race.sas.com/GEL/workshops/PSGEL263-sas-viya-4.0.1-advanced-topics-in-authentication/-/raw/master/scripts/TLS/GELEnvRootCA/ca_cert.pem \
    -o ${FOLDER_NAME}/site-config/security/cacerts/ca_cert.pem


    # Create Ingress YAML
    tee ${FOLDER_NAME}/site-config/security/cert-manager-provided-ingress-certificate.yaml > /dev/null <<EOF
    ---
    apiVersion: builtin
    kind: PatchTransformer
    metadata:
      name: sas-cert-manager-ingress-annotation-transformer
    patch: |-
      - op: add
        path: /metadata/annotations/cert-manager.io~1issuer
        value: sas-viya-issuer
    target:
      kind: Ingress
      name: .*
    EOF

    # Create Issuer YAML files
    tee ${FOLDER_NAME}/site-config/security/cert-manager-issuer/kustomization.yaml > /dev/null <<EOF
    resources:
    - resources.yaml
    EOF

    export BASE64_CA=`cat ${FOLDER_NAME}/site-config/security/cacerts/ca_cert.pem|base64|tr -d '\n'`
    export BASE64_CERT=`cat ${FOLDER_NAME}/site-config/security/cacerts/intermediate.cert.pem|base64|tr -d '\n'`
    export BASE64_KEY=`cat ${FOLDER_NAME}/site-config/security/cacerts/intermediate.key.pem|base64|tr -d '\n'`

    tee ${FOLDER_NAME}/site-config/security/cert-manager-issuer/resources.yaml > /dev/null <<EOF
    ---
    # sas-viya-ca-certificate.yaml
    # ............................
    apiVersion: v1
    kind: Secret
    metadata:
      name: sas-viya-ca-certificate-secret
    data:
      ca.crt: $BASE64_CA
      tls.crt: $BASE64_CERT
      tls.key: $BASE64_KEY
    ---
    # sas-viya-issuer.yaml
    # ....................
    apiVersion: cert-manager.io/v1alpha2
    kind: Issuer
    metadata:
      name: sas-viya-issuer
    spec:
      ca:
        secretName: sas-viya-ca-certificate-secret
    EOF



    ```

#### Kustomization-lts

1. create kustomization.yaml

    ```bash

    INGRESS_SUFFIX=$(hostname -f)
    echo $INGRESS_SUFFIX

    cd ${FOLDER_NAME}
    #rm ./gelldap
    #ln -s ~/project/gelldap ./gelldap

    bash -c "cat << EOF > ${FOLDER_NAME}/kustomization.yaml.tls
    ---
    namespace: ${NS}
    resources:
      - sas-bases/base
      #- sas-bases/overlays/cert-manager-issuer     # TLS
      - site-config/security/cert-manager-issuer
      - sas-bases/overlays/network/ingress
      - sas-bases/overlays/network/ingress/security   # TLS
      - sas-bases/overlays/internal-postgres
      - sas-bases/overlays/crunchydata
      - sas-bases/overlays/cas-server
      - sas-bases/overlays/update-checker       # added update checker
      #- gelldap/no_TLS
      #- sas-bases/overlays/cas-server/auto-resources    # CAS-related
    ## added in .0.6
    configurations:
      - sas-bases/overlays/required/kustomizeconfig.yaml
    transformers:
      - sas-bases/overlays/network/ingress/security/transformers/product-tls-transformers.yaml   # TLS
      - sas-bases/overlays/network/ingress/security/transformers/ingress-tls-transformers.yaml   # TLS
      - sas-bases/overlays/network/ingress/security/transformers/backend-tls-transformers.yaml   # TLS
      - sas-bases/overlays/required/transformers.yaml
      - sas-bases/overlays/internal-postgres/internal-postgres-transformer.yaml
      - site-config/security/cert-manager-provided-ingress-certificate.yaml     # TLS
      - site-config/daily_update_check.yaml      # change the frequency of the update-check
      #- sas-bases/overlays/cas-server/auto-resources/remove-resources.yaml    # CAS-related
      - site-config/cas-default_secondary_controller.yaml
      - site-config/cas-default_workers.yaml
      #- sas-bases/overlays/scaling/zero-scale/phase-0-transformer.yaml
      #- sas-bases/overlays/scaling/zero-scale/phase-1-transformer.yaml
    generators:
      - site-config/postgres/postgres-custom-config.yaml
    configMapGenerator:
      - name: ingress-input
        behavior: merge
        literals:
          - INGRESS_HOST=${INGRESS_PREFIX}.${INGRESS_SUFFIX}
      - name: sas-shared-config
        behavior: merge
        literals:
          - SAS_SERVICES_URL=https://${INGRESS_PREFIX}.${INGRESS_SUFFIX}
      - name: sas-consul-config            ## This injects content into consul. You can add, but not replace
        behavior: merge
        files:
          - SITEDEFAULT_CONF=site-config/gelldap-sitedefault.yaml
    EOF"


    ```

#### build

1. build

    ```bash

    cd  ${FOLDER_NAME}/


    rm -f kustomization.yaml
    ln -s kustomization.yaml.tls kustomization.yaml
    time kustomize build -o site.yaml.tls

    ## choose which one we want
    rm -f site.yaml
    ln -s site.yaml.tls site.yaml
    ```

#### apply LTS, conditionally on description

1. apply

    ```bash

    cd  ${FOLDER_NAME}/

    if [[ "$description" == *"_LTS_"* ]]  ; then

        kubectl  -n ${NS}  apply   --selector="sas.com/admin=cluster-wide" -f site.yaml
        time kubectl wait  --for condition=established --timeout=60s -l "sas.com/admin=cluster-wide" crd
        kubectl  -n ${NS} apply  --selector="sas.com/admin=cluster-local" -f site.yaml --prune
        kubectl  -n ${NS} apply  --selector="sas.com/admin=namespace" -f site.yaml --prune

        kubectl  -n ${NS} apply -f site.yaml
    fi

    ```

#### Urls

1. Urls

    ```bash
    printf "\n* [Viya Drive (${NS}) URL (HTTP**S**)](https://${INGRESS_PREFIX}.$(hostname -f)/SASDrive )\n\n" | tee -a /home/cloud-user/urls.md
    printf "\n* [Viya Environment Manager (${NS}) URL (HTTP**S**)](https://${INGRESS_PREFIX}.$(hostname -f)/SASEnvironmentManager )\n\n" | tee -a /home/cloud-user/urls.md
    ```


### CADENCE: Stable

#### default values for variables

```bash
NS=gelenv
CADENCE_NAME='stable'
CADENCE_VERSION='2020.1.4'
ORDER=${ORDER:-9CDZDD}
INGRESS_PREFIX=${NS}
FOLDER_NAME=~/project/deploy/${NS}-${CADENCE_NAME}
```

#### prep namespace

1. create folders and namespaces

    ```bash
    mkdir -p ~/project
    mkdir -p ${FOLDER_NAME}
    mkdir -p ${FOLDER_NAME}/site-config

    tee  ${FOLDER_NAME}/namespace.yaml > /dev/null << EOF
    ---
    apiVersion: v1
    kind: Namespace
    metadata:
      name: ${NS}
      labels:
        name: "${NS}_namespace"
    EOF

    kubectl apply -f ${FOLDER_NAME}/namespace.yaml

    kubectl get ns

    ```

#### ldap

1. gelldap and gelmail

    ```bash

    cd ~/project/
    git clone https://gelgitlab.race.sas.com/GEL/utilities/gelldap.git
    cd ~/project/gelldap/
    git fetch --all
    GELLDAP_BRANCH=int_images
    git reset --hard origin/${GELLDAP_BRANCH}

    cd ~/project/gelldap/
    kustomize build ./no_TLS/ | kubectl -n ${NS} apply -f -

    cp ~/project/gelldap/no_TLS/gelldap-sitedefault.yaml \
           ${FOLDER_NAME}/site-config/

    ```

#### get order

1. copy order stuff

    ```bash


    ORDER_FILE=$(ls ~/orders/ \
        | grep ${ORDER} \
        | grep ${CADENCE_NAME} \
        | grep ${CADENCE_VERSION} \
        | sort \
        | tail -n 1 \
        )

    #SASViyaV4_9CDZDD_0_stable_2020.0.4_20200821.1598037827526_deploymentAssets_2020-08-24T165225
    echo $ORDER_FILE

    cp ~/orders/${ORDER_FILE} ${FOLDER_NAME}/
    cd  ${FOLDER_NAME}/

    rm -rf ./sas-bases/
    tar xf ${ORDER_FILE}

    ```

<!--
1. override with mirrored order:

    ```sh
    rm -rf ./sas-bases/
    rm -rf *.tgz

    echo "09RG3K" > ~/dailymirror.txt

    curl https://gelweb.race.sas.com/scripts/PSGEL255/orders/$(cat ~/dailymirror.txt).kustomize.tgz \
        -o ${FOLDER_NAME}/dailymirror.tgz

    cd  ${FOLDER_NAME}/

    tar xf dailymirror.tgz

    ```
 -->


#### Daily update-checker run

1. create a transformer to run this very often:

    ```bash

    bash -c "cat << EOF > ${FOLDER_NAME}/site-config/daily_update_check.yaml
    apiVersion: builtin
    kind: PatchTransformer
    metadata:
      name: daily-update-check
    patch: |-
      - op: replace
        path: /spec/schedule
        value: '00,15,30,45 * * * *'
      - op: replace
        path: /spec/successfulJobsHistoryLimit
        value: 24
    target:
      name: sas-update-checker
      kind: CronJob
    EOF"

    ```

#### MPP CAS:

1. MPP CAS with secondary controller

    ```bash
    bash -c "cat << EOF > ${FOLDER_NAME}/site-config/cas-default_secondary_controller.yaml
    ---
    apiVersion: builtin
    kind: PatchTransformer
    metadata:
      name: cas-add-backup-default
    patch: |-
       - op: replace
         path: /spec/backupControllers
         value:
           1
    target:
      group: viya.sas.com
      kind: CASDeployment
      labelSelector: "sas.com/cas-server-default"
      version: v1alpha1
    EOF"

    bash -c "cat << EOF > ${FOLDER_NAME}/site-config/cas-default_workers.yaml
    ---
    apiVersion: builtin
    kind: PatchTransformer
    metadata:
      name: cas-add-workers-default
    patch: |-
       - op: replace
         path: /spec/workers
         value:
           4
    target:
      group: viya.sas.com
      kind: CASDeployment
      labelSelector: "sas.com/cas-server-default"
      version: v1alpha1
    EOF"

    ```

#### Crunchy postgres needs a special file

1. so the postgres readme states:

    ```bash

    mkdir -p ${FOLDER_NAME}/site-config/postgres
    #cp ${FOLDER_NAME}/sas-bases/examples/configure-postgres/internal/custom-config/postgres-custom-config.yaml \
    #    ${FOLDER_NAME}/site-config/postgres/postgres-custom-config.yaml

    cat ${FOLDER_NAME}/sas-bases/examples/configure-postgres/internal/custom-config/postgres-custom-config.yaml | \
        sed 's|\-\ {{\ HBA\-CONF\-HOST\-OR\-HOSTSSL\ }}|- hostssl|g' | \
        sed 's|\ {{\ PASSWORD\-ENCRYPTION\ }}| scram-sha-256|g' | \
        sed 's|scram-sha-256 should|{{\ PASSWORD\-ENCRYPTION\ }}\ should|g' | \
        sed 's|scram-sha-256 # Added|scram-sha-256             # Added|g' | \
        sed 's|max_wal_size: 2GB|max_wal_size: 1GB|g' | \
        sed 's|wal_keep_segments: 1000|wal_keep_segments: 512 |g' \
        > ${FOLDER_NAME}/site-config/postgres/postgres-custom-config.yaml

    ```

#### TLS work

* from Stuart

    ```bash
    mkdir -p ${FOLDER_NAME}/site-config/security/cacerts
    mkdir -p ${FOLDER_NAME}/site-config/security/cert-manager-issuer

    # Download Intermediate CA cert and key
    curl -sk https://gelgitlab.race.sas.com/GEL/workshops/PSGEL263-sas-viya-4.0.1-advanced-topics-in-authentication/-/raw/master/scripts/TLS/GELEnvRootCA/intermediate.cert.pem \
    -o ${FOLDER_NAME}/site-config/security/cacerts/intermediate.cert.pem
    curl -sk https://gelgitlab.race.sas.com/GEL/workshops/PSGEL263-sas-viya-4.0.1-advanced-topics-in-authentication/-/raw/master/scripts/TLS/GELEnvRootCA/intermediate.key.pem \
    -o ${FOLDER_NAME}/site-config/security/cacerts/intermediate.key.pem

    # Download CA cert
    curl -sk https://gelgitlab.race.sas.com/GEL/workshops/PSGEL263-sas-viya-4.0.1-advanced-topics-in-authentication/-/raw/master/scripts/TLS/GELEnvRootCA/ca_cert.pem \
    -o ${FOLDER_NAME}/site-config/security/cacerts/ca_cert.pem


    # Create Ingress YAML
    tee ${FOLDER_NAME}/site-config/security/cert-manager-provided-ingress-certificate.yaml > /dev/null <<EOF
    ---
    apiVersion: builtin
    kind: PatchTransformer
    metadata:
      name: sas-cert-manager-ingress-annotation-transformer
    patch: |-
      - op: add
        path: /metadata/annotations/cert-manager.io~1issuer
        value: sas-viya-issuer
    target:
      kind: Ingress
      name: .*
    EOF

    # Create Issuer YAML files
    tee ${FOLDER_NAME}/site-config/security/cert-manager-issuer/kustomization.yaml > /dev/null <<EOF
    resources:
    - resources.yaml
    EOF

    export BASE64_CA=`cat ${FOLDER_NAME}/site-config/security/cacerts/ca_cert.pem|base64|tr -d '\n'`
    export BASE64_CERT=`cat ${FOLDER_NAME}/site-config/security/cacerts/intermediate.cert.pem|base64|tr -d '\n'`
    export BASE64_KEY=`cat ${FOLDER_NAME}/site-config/security/cacerts/intermediate.key.pem|base64|tr -d '\n'`

    tee ${FOLDER_NAME}/site-config/security/cert-manager-issuer/resources.yaml > /dev/null <<EOF
    ---
    # sas-viya-ca-certificate.yaml
    # ............................
    apiVersion: v1
    kind: Secret
    metadata:
      name: sas-viya-ca-certificate-secret
    data:
      ca.crt: $BASE64_CA
      tls.crt: $BASE64_CERT
      tls.key: $BASE64_KEY
    ---
    # sas-viya-issuer.yaml
    # ....................
    apiVersion: cert-manager.io/v1alpha2
    kind: Issuer
    metadata:
      name: sas-viya-issuer
    spec:
      ca:
        secretName: sas-viya-ca-certificate-secret
    EOF

    ```

#### Kustomization-stable

1. create kustomization.yaml

    ```bash

    INGRESS_SUFFIX=$(hostname -f)
    echo $INGRESS_SUFFIX

    cd ${FOLDER_NAME}
    #rm ./gelldap
    #ln -s ~/project/gelldap ./gelldap

    bash -c "cat << EOF > ${FOLDER_NAME}/kustomization.yaml.tls
    ---
    namespace: ${NS}
    resources:
      - sas-bases/base
      #- sas-bases/overlays/cert-manager-issuer     # TLS
      - site-config/security/cert-manager-issuer
      - sas-bases/overlays/network/ingress
      - sas-bases/overlays/network/ingress/security   # TLS
      - sas-bases/overlays/internal-postgres
      - sas-bases/overlays/crunchydata
      - sas-bases/overlays/internal-elasticsearch   # Stable 2020.1.3
      - sas-bases/overlays/cas-server
      - sas-bases/overlays/update-checker       # added update checker
      #- gelldap/no_TLS
      #- sas-bases/overlays/cas-server/auto-resources    # CAS-related
    ## added in .0.6
    configurations:
      - sas-bases/overlays/required/kustomizeconfig.yaml
    transformers:
      - sas-bases/overlays/network/ingress/security/transformers/product-tls-transformers.yaml   # TLS
      - sas-bases/overlays/network/ingress/security/transformers/ingress-tls-transformers.yaml   # TLS
      - sas-bases/overlays/network/ingress/security/transformers/backend-tls-transformers.yaml   # TLS
      - sas-bases/overlays/internal-elasticsearch/sysctl-transformer.yaml                    # Stable 2020.1.3
      - sas-bases/overlays/required/transformers.yaml
      - sas-bases/overlays/internal-postgres/internal-postgres-transformer.yaml
      - site-config/security/cert-manager-provided-ingress-certificate.yaml     # TLS
      - site-config/daily_update_check.yaml      # change the frequency of the update-check
      #- sas-bases/overlays/cas-server/auto-resources/remove-resources.yaml    # CAS-related
      - sas-bases/overlays/internal-elasticsearch/internal-elasticsearch-transformer.yaml    # Stable 2020.1.3
      - site-config/cas-default_secondary_controller.yaml
      - site-config/cas-default_workers.yaml
      #- sas-bases/overlays/scaling/zero-scale/phase-0-transformer.yaml
      #- sas-bases/overlays/scaling/zero-scale/phase-1-transformer.yaml
    generators:
      - site-config/postgres/postgres-custom-config.yaml
    configMapGenerator:
      - name: ingress-input
        behavior: merge
        literals:
          - INGRESS_HOST=${INGRESS_PREFIX}.${INGRESS_SUFFIX}
      - name: sas-shared-config
        behavior: merge
        literals:
          - SAS_SERVICES_URL=https://${INGRESS_PREFIX}.${INGRESS_SUFFIX}
      - name: sas-consul-config            ## This injects content into consul. You can add, but not replace
        behavior: merge
        files:
          - SITEDEFAULT_CONF=site-config/gelldap-sitedefault.yaml
      # # This is to fix an issue that only appears in RACE Exnet.
      # # Do not do this at a customer site
      - name: sas-go-config
        behavior: merge
        literals:
          - SAS_BOOTSTRAP_HTTP_CLIENT_TIMEOUT_REQUEST='5m'
    EOF"
    ```

#### build

1. build

    ```bash

    cd  ${FOLDER_NAME}/


    rm -f kustomization.yaml
    ln -s kustomization.yaml.tls kustomization.yaml
    time kustomize build -o site.yaml.tls

    ## choose which one we want
    rm -f site.yaml
    ln -s site.yaml.tls site.yaml
    ```

#### apply STABLE, conditional on description

1. apply

    ```bash
    cd  ${FOLDER_NAME}/

    if [[ "$description" == *"_STABLE_"* ]]  ; then

        kubectl  -n ${NS}  apply   --selector="sas.com/admin=cluster-wide" -f site.yaml                    | tee /tmp/site_apply1.log
        time kubectl wait  --for condition=established --timeout=60s -l "sas.com/admin=cluster-wide" crd   | tee /tmp/site_wait.log
        kubectl  -n ${NS} apply  --selector="sas.com/admin=cluster-local" -f site.yaml --prune             | tee /tmp/site_apply2.log
        kubectl  -n ${NS} apply  --selector="sas.com/admin=namespace" -f site.yaml --prune                 | tee /tmp/site_apply3.log

        kubectl  -n ${NS} apply -f site.yaml

    fi


    ```

#### Urls

1. Urls

    ```bash
    #printf "\n* [Viya Drive (${NS}) URL (HTTP )](http://${INGRESS_PREFIX}.$(hostname -f)/SASDrive )\n\n" | tee -a /home/cloud-user/urls.md
    #printf "\n* [Viya Drive (${NS}) URL (HTTP**S**)](https://${INGRESS_PREFIX}.$(hostname -f)/SASDrive )\n\n" | tee -a /home/cloud-user/urls.md
    #printf "\n* [Viya Environment Manager (${NS}) URL (HTTP)](http://${INGRESS_PREFIX}.$(hostname -f)/SASEnvironmentManager )\n\n" | tee -a /home/cloud-user/urls.md
    #printf "\n* [Viya Environment Manager (${NS}) URL (HTTP**S**)](https://${INGRESS_PREFIX}.$(hostname -f)/SASEnvironmentManager )\n\n" | tee -a /home/cloud-user/urls.md
    ```


## IF_END for 5-machine-collection

1. end the if

    ```bash

    fi

    #echo "Done kicking off the gelenv-stable and gelenv-lts environments"
    #echo " feel free to 'kubecl delete ns' the one you are not interested in"
    #echo "if you want to wait until one is ready, then do:"
    #echo "   NS=<your_ns>"
    #echo "   time kubectl -n ${NS} wait --for=condition=ready pod --selector='app.kubernetes.io/name=sas-readiness'  --timeout=2700s"

    echo "Done kicking off the gelenv-lts environment"
    echo "if you want to wait until one is ready, then do:"
    echo "   NS=gelenv-lts"
    echo "   time kubectl -n gelenv-lts wait --for=condition=ready pod --selector='app.kubernetes.io/name=sas-readiness'  --timeout=2700s"


    ```

## IF_BEGIN for 1-machine-collection

1. begin the if

    ```bash
    source <( cat /opt/raceutils/.bootstrap.txt  )
    source <( cat /opt/raceutils/.id.txt  )

    if  [ "$collection_size" -eq "2"  ] ; then
    ```


### Labels and taints

* clear it all up

    ```bash
    kubectl label nodes \
        $(hostname)  \
        workload.sas.com/class-          --overwrite
    kubectl taint nodes \
        $(hostname)    \
        workload.sas.com/class-          --overwrite
    ```

* start with labels

    ```bash
    kubectl label nodes \
         $(hostname)   \
        workload.sas.com/class=compute          --overwrite

    ```

### CADENCE: LTS

#### default values for variables

```bash
    NS=gelenv-lts
    CADENCE_NAME='lts'
    CADENCE_VERSION='2020.1'
    ORDER=${ORDER:-9CDZDD}
    INGRESS_PREFIX=${NS}
    FOLDER_NAME=~/project/deploy/${NS}
    READINESS_TIMEOUT=5s
```

#### prep NS

1. create folders and namespaces

    ```bash
    mkdir -p ~/project
    mkdir -p ${FOLDER_NAME}
    mkdir -p ${FOLDER_NAME}/site-config

    tee  ${FOLDER_NAME}/namespace.yaml > /dev/null << EOF
    ---
    apiVersion: v1
    kind: Namespace
    metadata:
      name: ${NS}
      labels:
        name: "${NS}_namespace"
    EOF

    kubectl apply -f ${FOLDER_NAME}/namespace.yaml

    kubectl get ns

    ```

#### ldap

1. gelldap and gelmail

    ```bash

    cd ~/project/
    git clone https://gelgitlab.race.sas.com/GEL/utilities/gelldap.git
    cd ~/project/gelldap/
    git fetch --all
    GELLDAP_BRANCH=int_images
    git reset --hard origin/${GELLDAP_BRANCH}

    cd ~/project/gelldap/
    kustomize build ./no_TLS/ | kubectl -n ${NS} apply -f -

    cp ~/project/gelldap/no_TLS/gelldap-sitedefault.yaml \
           ${FOLDER_NAME}/site-config/

    ```

#### Choose order

1. copy order stuff

    ```bash


    ORDER_FILE=$(ls ~/orders/ \
        | grep ${ORDER} \
        | grep ${CADENCE_NAME} \
        | grep ${CADENCE_VERSION} \
        | sort \
        | tail -n 1 \
        )

    #SASViyaV4_9CDZDD_0_stable_2020.0.4_20200821.1598037827526_deploymentAssets_2020-08-24T165225
    echo $ORDER_FILE

    cp ~/orders/${ORDER_FILE} ${FOLDER_NAME}/
    cd  ${FOLDER_NAME}/

    rm -rf ./sas-bases/
    tar xf ${ORDER_FILE}

    ```


#### Crunchy postgres needs a special file

1. so the postgres readme states:

    ```bash

    mkdir -p ${FOLDER_NAME}/site-config/postgres
    #cp ${FOLDER_NAME}/sas-bases/examples/configure-postgres/internal/custom-config/postgres-custom-config.yaml \
    #    ${FOLDER_NAME}/site-config/postgres/postgres-custom-config.yaml

    cat ${FOLDER_NAME}/sas-bases/examples/configure-postgres/internal/custom-config/postgres-custom-config.yaml | \
        sed 's|\-\ {{\ HBA\-CONF\-HOST\-OR\-HOSTSSL\ }}|- hostssl|g' | \
        sed 's|\ {{\ PASSWORD\-ENCRYPTION\ }}| scram-sha-256|g' | \
        sed 's|scram-sha-256 should|{{\ PASSWORD\-ENCRYPTION\ }}\ should|g' | \
        sed 's|scram-sha-256 # Added|scram-sha-256             # Added|g' | \
        sed 's|max_wal_size: 2GB|max_wal_size: 1GB|g' | \
        sed 's|wal_keep_segments: 1000|wal_keep_segments: 512 |g' \
        > ${FOLDER_NAME}/site-config/postgres/postgres-custom-config.yaml

    ```

#### make is smaller footprint:

1. smaller

    ```bash

    stop_these="(sas-business-rules-services,sas-connect,sas-connect-spawner,sas-data-quality-services,sas-decision-manager-app,sas-decisions-definitions,sas-esp-operator,sas-forecasting-comparison,sas-forecasting-events,sas-forecasting-exploration,sas-forecasting-filters,sas-forecasting-pipelines,sas-forecasting-services,sas-job-flow-scheduling,sas-microanalytic-score,sas-model-management,sas-model-manager-app,sas-subject-contacts,as-text-analyticssas-text-cas-data-management,sas-text-categorization,sas-text-concepts,sas-text-parsing,sas-text-sentiment,sas-text-topics,sas-topic-management,sas-workflow,sas-workflow-definition-history,sas-workflow-manager-app)"


    bash -c "cat << EOF > ~/project/deploy/${NS}/minimal_deploy.yaml
    ---
    apiVersion: builtin
    kind: PatchTransformer
    metadata:
      name: partial_stop
    patch: |-
      - op: replace
        path: /spec/replicas
        value: 0
    target:
      kind: Deployment
      version: v1
      group: apps
      labelSelector: app.kubernetes.io/name in ${stop_these}
    ---

    EOF"

    bash -c "cat << EOF > ~/project/deploy/${NS}/cpu_requests_lowerer.yaml
    - op: add
      path: /spec/template/spec/containers/0/resources/requests/cpu
      value: 10m
    EOF"


    ```

#### TLS work

* from Stuart

    ```bash
    mkdir -p ${FOLDER_NAME}/site-config/security/cacerts
    mkdir -p ${FOLDER_NAME}/site-config/security/cert-manager-issuer

    # Download Intermediate CA cert and key
    curl -sk https://gelgitlab.race.sas.com/GEL/workshops/PSGEL263-sas-viya-4.0.1-advanced-topics-in-authentication/-/raw/master/scripts/TLS/GELEnvRootCA/intermediate.cert.pem \
    -o ${FOLDER_NAME}/site-config/security/cacerts/intermediate.cert.pem
    curl -sk https://gelgitlab.race.sas.com/GEL/workshops/PSGEL263-sas-viya-4.0.1-advanced-topics-in-authentication/-/raw/master/scripts/TLS/GELEnvRootCA/intermediate.key.pem \
    -o ${FOLDER_NAME}/site-config/security/cacerts/intermediate.key.pem

    # Download CA cert
    curl -sk https://gelgitlab.race.sas.com/GEL/workshops/PSGEL263-sas-viya-4.0.1-advanced-topics-in-authentication/-/raw/master/scripts/TLS/GELEnvRootCA/ca_cert.pem \
    -o ${FOLDER_NAME}/site-config/security/cacerts/ca_cert.pem


    # Create Ingress YAML
    tee ${FOLDER_NAME}/site-config/security/cert-manager-provided-ingress-certificate.yaml > /dev/null <<EOF
    ---
    apiVersion: builtin
    kind: PatchTransformer
    metadata:
      name: sas-cert-manager-ingress-annotation-transformer
    patch: |-
      - op: add
        path: /metadata/annotations/cert-manager.io~1issuer
        value: sas-viya-issuer
    target:
      kind: Ingress
      name: .*
    EOF

    # Create Issuer YAML files
    tee ${FOLDER_NAME}/site-config/security/cert-manager-issuer/kustomization.yaml > /dev/null <<EOF
    resources:
    - resources.yaml
    EOF

    export BASE64_CA=`cat ${FOLDER_NAME}/site-config/security/cacerts/ca_cert.pem|base64|tr -d '\n'`
    export BASE64_CERT=`cat ${FOLDER_NAME}/site-config/security/cacerts/intermediate.cert.pem|base64|tr -d '\n'`
    export BASE64_KEY=`cat ${FOLDER_NAME}/site-config/security/cacerts/intermediate.key.pem|base64|tr -d '\n'`

    tee ${FOLDER_NAME}/site-config/security/cert-manager-issuer/resources.yaml > /dev/null <<EOF
    ---
    # sas-viya-ca-certificate.yaml
    # ............................
    apiVersion: v1
    kind: Secret
    metadata:
      name: sas-viya-ca-certificate-secret
    data:
      ca.crt: $BASE64_CA
      tls.crt: $BASE64_CERT
      tls.key: $BASE64_KEY
    ---
    # sas-viya-issuer.yaml
    # ....................
    apiVersion: cert-manager.io/v1alpha2
    kind: Issuer
    metadata:
      name: sas-viya-issuer
    spec:
      ca:
        secretName: sas-viya-ca-certificate-secret
    EOF



    ```

#### Kustomization

1. create kustomization.yaml

    ```bash

    INGRESS_SUFFIX=$(hostname -f)
    echo $INGRESS_SUFFIX

    cd ${FOLDER_NAME}
    #rm ./gelldap
    #ln -s ~/project/gelldap ./gelldap

    bash -c "cat << EOF > ${FOLDER_NAME}/kustomization.yaml.tls
    ---
    namespace: ${NS}
    resources:
      - sas-bases/base
      #- sas-bases/overlays/cert-manager-issuer     # TLS
      - site-config/security/cert-manager-issuer
      - sas-bases/overlays/network/ingress
      - sas-bases/overlays/network/ingress/security   # TLS
      - sas-bases/overlays/internal-postgres
      - sas-bases/overlays/crunchydata
      - sas-bases/overlays/cas-server
      - sas-bases/overlays/update-checker       # added update checker
      #- sas-bases/overlays/cas-server/auto-resources    # CAS-related
    configurations:
      - sas-bases/overlays/required/kustomizeconfig.yaml
    transformers:
      - sas-bases/overlays/network/ingress/security/transformers/product-tls-transformers.yaml   # TLS
      - sas-bases/overlays/network/ingress/security/transformers/ingress-tls-transformers.yaml   # TLS
      - sas-bases/overlays/network/ingress/security/transformers/backend-tls-transformers.yaml   # TLS
      - sas-bases/overlays/required/transformers.yaml
      - sas-bases/overlays/internal-postgres/internal-postgres-transformer.yaml
      - site-config/security/cert-manager-provided-ingress-certificate.yaml     # TLS
      #- sas-bases/overlays/cas-server/auto-resources/remove-resources.yaml    # CAS-related
      #- sas-bases/overlays/scaling/zero-scale/phase-0-transformer.yaml
      #- sas-bases/overlays/scaling/zero-scale/phase-1-transformer.yaml
      - minimal_deploy.yaml
    generators:
      - site-config/postgres/postgres-custom-config.yaml
    configMapGenerator:
      - name: ingress-input
        behavior: merge
        literals:
          - INGRESS_HOST=${INGRESS_PREFIX}.${INGRESS_SUFFIX}
      - name: sas-shared-config
        behavior: merge
        literals:
          - SAS_SERVICES_URL=https://${INGRESS_PREFIX}.${INGRESS_SUFFIX}
      - name: sas-consul-config            ## This injects content into consul. You can add, but not replace
        behavior: merge
        files:
          - SITEDEFAULT_CONF=site-config/gelldap-sitedefault.yaml
    patches:
      - path: cpu_requests_lowerer.yaml
        target:
          kind: Deployment
          LabelSelector: sas.com/deployment-base in (spring,go)

    EOF"

    ```

#### build and apply lts for single-machine

1. build

    ```bash

    cd  ${FOLDER_NAME}/


    rm -f kustomization.yaml
    ln -s kustomization.yaml.tls kustomization.yaml
    time kustomize build -o site.yaml.tls

    ## choose which one we want
    rm -f site.yaml
    ln -s site.yaml.tls site.yaml
    ```

1. apply

    ```bash
    kubectl -n cert-manager scale deployment cert-manager --replicas=1
    kubectl -n nginx scale deployment my-nginx-nginx-ingress-controller --replicas=1

    if [[ "$description" == *"_LTS_"* ]]  ; then

        cd  ${FOLDER_NAME}/

        kubectl  -n ${NS}  apply   --selector="sas.com/admin=cluster-wide" -f site.yaml
        time kubectl wait  --for condition=established --timeout=60s -l "sas.com/admin=cluster-wide" crd
        kubectl  -n ${NS} apply  --selector="sas.com/admin=cluster-local" -f site.yaml --prune
        kubectl  -n ${NS} apply  --selector="sas.com/admin=namespace" -f site.yaml --prune

        kubectl  -n ${NS} apply -f site.yaml

    fi

    ```

#### Urls

1. Urls

    ```bash
    printf "\n* [Viya Drive (${NS}) URL (HTTP**S**)](https://${INGRESS_PREFIX}.$(hostname -f)/SASDrive )\n\n" | tee -a /home/cloud-user/urls.md
    printf "\n* [Viya Environment Manager (${NS}) URL (HTTP**S**)](https://${INGRESS_PREFIX}.$(hostname -f)/SASEnvironmentManager )\n\n" | tee -a /home/cloud-user/urls.md
    ```

## IF_END for 1-machine-collection

1. end the if

    ```bash

    fi
    ```


## IF_BEGIN for Admin Autodeploy Collection

1. begin the if

    ```bash
    source <( cat /opt/raceutils/.bootstrap.txt  )
    source <( cat /opt/raceutils/.id.txt  )

    #if  [ "$collection_size" -gt "10"  ] ; then
    if [[ "$description" == *"_AUTODEPLOY_ADMIN_"* ]]  ; then

    ```

### run the script

1. this is what the admin student is supposed to execute

    ```bash
    source ~/PSGEL260-sas-viya-4.0.1-administration/scripts/setupViyaAdminWorkshop.sh \
        | tee ~/PSGEL260-sas-viya-4.0.1-administration/scripts/setupViyaAdminWorkshop.log

    ```

## IF_END Admin Autodeploy Collection

1. end the if

    ```bash
    fi
    ```


## IF_BEGIN for Migration Autodeploy Collection

1. begin the if

    ```bash
    source <( cat /opt/raceutils/.bootstrap.txt  )
    source <( cat /opt/raceutils/.id.txt  )

    #if  [ "$collection_size" -gt "10"  ] ; then
    if [[ "$description" == *"_AUTODEPLOY_MIGRATION_"* ]]  ; then

    ```

### run the script

1. this is what the admin student is supposed to execute

    ```bash
    source  ~/PSGEL270-sas-viya-migration-and-promotion/scripts/deployViya.sh from35 \
        | tee ~/PSGEL270-sas-viya-migration-and-promotion/scripts/setupViyaMigration.log

    ```

## IF_END Migration Autodeploy Collection

1. end the if

    ```bash
    fi
    ```
