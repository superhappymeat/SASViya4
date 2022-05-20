![Global Enablement & Learning](https://gelgitlab.race.sas.com/GEL/utilities/writing-content-in-markdown/-/raw/master/img/gel_banner_logo_tech-partners.jpg)

# Using the Deployment Operator with a Git Repository

* [Introduction](#introduction)
* [Using the Deployment Operator to deploy a specific version (CADENCE_RELEASE) of Viya](#using-the-deployment-operator-to-deploy-a-specific-version-cadence_release-of-viya)
  * [Step 1. Extract the order secrets](#step-1-extract-the-order-secrets)
  * [Step 2. Create the Viya configuration for Discovery](#step-2-create-the-viya-configuration-for-discovery)
    * [2.1 Configure Crunchy for TLS](#21-configure-crunchy-for-tls)
    * [2.2 Creating a TLS-related file in `./site-config/`](#22-creating-a-tls-related-file-in-site-config)
    * [2.3 Create the sitedefault file](#23-create-the-sitedefault-file)
    * [2.4 Create the storage class patch for AzureFiles](#24-create-the-storage-class-patch-for-azurefiles)
    * [2.5 Create the kustomization.yaml file](#25-create-the-kustomizationyaml-file)
    * [2.6 Push the Viya configuration files to the Git project](#26-push-the-viya-configuration-files-to-the-git-project)
  * [Step 3. Create the deployment Custom Resource](#step-3-create-the-deployment-custom-resource)
  * [Step 4. Deploy GELLDAP to the Discovery namespace](#step-4-deploy-gelldap-to-the-discovery-namespace)
  * [Step 5. Apply the CR to deploy the discovery environment](#step-5-apply-the-cr-to-deploy-the-discovery-environment)
  * [Login to confirm you have a working environment (optional)](#login-to-confirm-you-have-a-working-environment-optional)
  * [Step 6. Confirm the version, and check for updates](#step-6-confirm-the-version-and-check-for-updates)
  * [Step 7. Apply hotfixes within the version](#step-7-apply-hotfixes-within-the-version)
  * [Review the deployment](#review-the-deployment)
* [Upgrade a Viya environment using the Operator](#upgrade-a-viya-environment-using-the-operator)
  * [Upgrade to 2020.1.5](#upgrade-to-202015)
    * [Step 1. Edit the CR, specify the new cadence version](#step-1-edit-the-cr-specify-the-new-cadence-version)
    * [Step 2. Upgrade the Discovery environment](#step-2-upgrade-the-discovery-environment)
    * [Final steps](#final-steps)
* [Making an admin change using the SAS Viya Deployment Operator](#making-an-admin-change-using-the-sas-viya-deployment-operator)
  * [Make a change to the deployment](#make-a-change-to-the-deployment)
  * [Applying the change to the environment](#applying-the-change-to-the-environment)
* [Next Steps](#next-steps)
  * [Table of Contents for the Deployment Operator exercises](#table-of-contents-for-the-deployment-operator-exercises)
* [Navigation](#navigation)

## Introduction

Now that you have deployed the SAS Viya Deployment Operator we can use it to deploy a SAS Viya environment.
The SAS Viya Deployment Operator watches the cluster for a SASDeployment custom resource. The data in the SASDeployment custom resource is used by the operator when installing SAS Viya.

There are two ways to provide the required files:

* In-line
* Using a Git repository.

In this exercise we will look at using the Git method, using the GitLab server that you set-up in the initial exercise.

This exercise assumes that you have completed the initial setup steps, [see here](./11_300_Deployment_Operator_environment_set-up.md).

To illustrate using the deployment operator, in this lab you will use the operator to perform the following tasks:

* Deploy a specific cadence release.
* Upgrade within that cadence release.
* Upgrade to a new cadence version.

## Using the Deployment Operator to deploy a specific version (CADENCE_RELEASE) of Viya

Earlier you created the GitLab server, in this exercise you will create a "**Discovery**" project that will be used to manage the files for the SAS environment.

Again, we will use the default Administration (root) user to simplify the exercise instructions.

Use the following steps to configure and deploy the SAS environment.

### Step 1. Extract the order secrets

For this you need the certificates that are contained in the `SASViyaV4_{order number}_certs.zip` file, as well as the license file.

1. Unzip the files.

    ```bash
    # Set environment variable
    DEPOP_VER=stable-2020.1.5

    # Create target directory
    mkdir -p ~/project/operator-driven/git-projects/discovery/secrets
    cd ~/project/operator-driven/git-projects/discovery/secrets
    #unzip files
    unzip ~/project/operator-setup/${DEPOP_VER}/SASViyaV4_*_certs.zip
    ```

1. Copy the license file.

   To make the next lab steps easier we will give the license file a generic name (**SASViyaV4_license.jwt**).

    ```bash
    # Create license directory
    mkdir -p ~/project/operator-driven/git-projects/discovery/secrets/license
    # Copy the files
    cp ~/project/operator-setup/${DEPOP_VER}/*.jwt ~/project/operator-driven/git-projects/discovery/secrets/license/SASViyaV4_license.jwt
    ```

### Step 2. Create the Viya configuration for Discovery

#### 2.1 Configure Crunchy for TLS

1. Following the instructions in the postgres README file, we are told to create this file.

    ```bash
    cd ~/project/operator-driven/git-projects/discovery

    mkdir -p ./site-config/postgres

    cat ~/project/operator-setup/${DEPOP_VER}/sas-bases/examples/configure-postgres/internal/custom-config/postgres-custom-config.yaml | \
    sed 's|\-\ {{\ HBA\-CONF\-HOST\-OR\-HOSTSSL\ }}|- hostssl|g' | \
    sed 's|\ {{\ PASSWORD\-ENCRYPTION\ }}| scram-sha-256|g' \
    > ./site-config/postgres/postgres-custom-config.yaml
    ```

#### 2.2 Creating a TLS-related file in `./site-config/`

2. Creating a TLS configuration.

    ```bash
    cd ~/project/operator-driven/git-projects/discovery
    mkdir -p ./site-config/security/
    # create the certificate issuer called "sas-viya-issuer"
    sed 's|{{.*}}|sas-viya-issuer|g' ~/project/operator-setup/${DEPOP_VER}/sas-bases/examples/security/cert-manager-provided-ingress-certificate.yaml  \
    > ./site-config/security/cert-manager-provided-ingress-certificate.yaml
    ```

#### 2.3 Create the sitedefault file

In this exercise we will use an OpenLDAP server (GELLDAP) deployed into the Viya namespace. The GELLDAP server comes with pre-written sitedefault and SSSD information.

3. Let's copy the provided file in the proper location. This is under the site-config folder

    ```bash
    # Copy the site-default file
    cp ~/project/operator-driven/git-projects/gelldap2/no_TLS/gelldap-sitedefault.yaml \
    ~/project/operator-driven/git-projects/discovery/site-config/
    ```

#### 2.4 Create the storage class patch for AzureFiles

1. Run this code to create a patch that we will reference in our kustomization.yaml file

    ```bash
    cd ~/project/operator-driven/git-projects/discovery/site-config/
    cat > ~/project/operator-driven/git-projects/discovery/site-config/storageclass.yaml <<-EOF
    kind: PersistentStorageClass
    metadata:
      name: wildcard
    spec:
      storageClassName: sas-azurefile #azurefile with sas UID/GID
    EOF
    ```

#### 2.5 Create the kustomization.yaml file

Now that you have created the above configuration files you need a kustomisation.yaml file that references them.

4. Issue the following command to create the kustomization.yaml file.

    ```bash
    NS=discovery
    STUDENT=$(cat ~/student.txt)
    INGRESS_FQDN=$STUDENT.gelsandbox.aks.unx.sas.com

    bash -c "cat << EOF > ~/project/operator-driven/git-projects/discovery/kustomization.yaml
    ---
    #namespace: discovery
    namespace: ${NS}
    resources:
      - sas-bases/base
      - sas-bases/overlays/cert-manager-issuer     # TLS
      - sas-bases/overlays/network/ingress
      - sas-bases/overlays/network/ingress/security   # TLS
      - sas-bases/overlays/internal-postgres
      - sas-bases/overlays/crunchydata
      - sas-bases/overlays/cas-server
      - sas-bases/overlays/internal-elasticsearch    # New Stable 2020.1.3
      - sas-bases/overlays/update-checker       # added update checker
      - sas-bases/overlays/cas-server/auto-resources    # CAS-related
    configurations:
      - sas-bases/overlays/required/kustomizeconfig.yaml  # required for 0.6
    transformers:
      - sas-bases/overlays/network/ingress/security/transformers/product-tls-transformers.yaml   # TLS
      - sas-bases/overlays/network/ingress/security/transformers/ingress-tls-transformers.yaml   # TLS
      - sas-bases/overlays/network/ingress/security/transformers/backend-tls-transformers.yaml   # TLS
      - sas-bases/overlays/internal-elasticsearch/sysctl-transformer.yaml                    # New Stable 2020.1.3
      - sas-bases/overlays/required/transformers.yaml
      - sas-bases/overlays/internal-postgres/internal-postgres-transformer.yaml
      - site-config/security/cert-manager-provided-ingress-certificate.yaml     # TLS
      - sas-bases/overlays/cas-server/auto-resources/remove-resources.yaml    # CAS-related
      - sas-bases/overlays/internal-elasticsearch/internal-elasticsearch-transformer.yaml    # New Stable 2020.1.3
      #- sas-bases/overlays/scaling/zero-scale/phase-0-transformer.yaml
      #- sas-bases/overlays/scaling/zero-scale/phase-1-transformer.yaml

    # set a custom Storage Class for PersistentVolumeClaims, as it's not currently possible to change the default SC in AKS
    # a new SC is required to support ReadWriteMany access
    # Note: annotationSelector is how we limit which PV use azurefiles/RWX versus default RWO.
    patches:
      - path: site-config/storageclass.yaml
        target:
          kind: PersistentVolumeClaim
          annotationSelector: sas.com/component-name in (sas-cas-operator,sas-backup-job,sas-event-stream-processing-studio-app,sas-reference-data-deploy-utilities,sas-data-quality-services,sas-model-publish,sas-commonfiles) # becomes default for sas-backup-job,sas-data-quality-services,sas-commonfiles with 2020.1.4
    configMapGenerator:
      - name: ingress-input
        behavior: merge
        literals:
          - INGRESS_HOST=${NS}.${INGRESS_FQDN}
      - name: sas-shared-config
        behavior: merge
        literals:
          - SAS_SERVICES_URL=https://${NS}.${INGRESS_FQDN}
      - name: sas-consul-config            ## This injects content into consul. You can add, but not replace
        behavior: merge
        files:
          - SITEDEFAULT_CONF=site-config/gelldap-sitedefault.yaml # point to our GELLDAP configured site-default
      # # This is to fix an issue that only appears in RACE Exnet.
      # # Do not do this at a customer site
      - name: sas-go-config
        behavior: merge
        literals:
          - SAS_BOOTSTRAP_HTTP_CLIENT_TIMEOUT_REQUEST='5m'
    generators:
      - site-config/postgres/postgres-custom-config.yaml
    EOF"
    ```

#### 2.6 Push the Viya configuration files to the Git project

Now we need to push the configuration files to the Git project to put them under version control.

1. Issue the following commands to push the files.

    ```sh
    cd ~/project/operator-driven/git-projects/discovery

    PROJECT_URL=http://gitlab.${INGRESS_FQDN}/root/discovery.git

    # Initialize the Discovery git repository
    git init
    git remote add origin $PROJECT_URL

    # Now push the file to your Git project
    git add .
    git commit -m "Initial commit of the Discovery configuration."

    # PUSH the files
    git push $PROJECT_URL
    ```

    The Discovery project should now have your Viya configuration files. Feel free to check!

    To get the URL and password for the admin user issue the following.

    ```sh
    cat ~/urls.md | grep GitLab
    ```

### Step 3. Create the deployment Custom Resource

The next step is to create the custom resource for the Discovery environment. But first some advice on creating the SASDeployment custom resource definition.

In order to use, or reference, the files storage in the Git project the 'userContent', license information and secrets all need to reference the Git project.

The deployment operator uses the HashiCorp 'Go-Getter' code. To understand the format of the reference see [HashiCorp's Go Getter](https://pkg.go.dev/github.com/hashicorp/go-getter@v1.4.1?tab=overview#url-format). For example, in your environment it would look something like the following.

```log
userContent:
  url: git::http://gitlab.<your_sas_ID>.gelsandbox.aks.unx.sas.com/root/discovery.git
```

Before you create the custom resource we need to add an annotation to ensure that all the configuration files are read when the 'kubectl apply' is issued. In the code below you will see a line with the following: `operator.sas.com/checksum: ""`

**So, why do you need to do this?**

The short answer is that the deployment operator is only looking for changes to a Custom Resource. If the CR exists and the change is in the kustomization.yaml or one of the other configuration files this wouldn't be picked up.

Changing the 'checksum' will force a change to trigger the deployment operator, the operator will then go and access and read ALL the YAML configuration (YAML) files. Thus updating your deployment. Later you will change the CAS Server configuration to illustrate this type of change.

*Please note, at the time of updating this lab exercise the need to null the checksum is undocumented.*

To deploy the SAS Viya environment using a custom resource that references the files in the GitLab project you would need to create the following.

```log
apiVersion: orchestration.sas.com/v1alpha1
kind: SASDeployment
metadata:
  annotations:
    environment.orchestration.sas.com/readOnlyRootFilesystem: "false"
    operator.sas.com/checksum: ""
  name: discovery-sasdeployment
spec:
  cadenceName: "stable"
  cadenceVersion: "2020.1.4"
  cadenceRelease: "20210406.1617742339205"
  repositoryWarehouse:
    url: https://ses.sas.download/ses           ## this is the default value
    updatePolicy: Never                         ## this is the default value. The alternative is 'Releases'
  # The following is an example of using URLs to specify user
  # content, a license, a client certificate, and a CA certiciate.
  userContent:
    # See HashiCorp's Go Getter "URL Format" documentation for details:
    #    https://pkg.go.dev/github.com/hashicorp/go-getter@v1.4.1?tab=overview#url-format
    url: git::http://gitlab.<your wildcard alias>/root/discovery.git
  license:
    url: http://gitlab.<your wildcard alias>/root/discovery/-/raw/master/secrets/license/SASViyaV4_license.jwt
  clientCertificate:
    url: http://gitlab.<your wildcard alias>/root/discovery/-/raw/master/secrets/entitlement-certificates/entitlement_certificate.pem
  caCertificate:
    url: http://gitlab.<your wildcard alias>/root/discovery/-/raw/master/secrets/ca-certificates/SAS_CA_Certificate.pem
```

*Note: You might have noticed that we have "hard-coded" the cadence version and release to use an older version of Viya. The goal is to show you (in the following steps) how to use the deployment operator to update the software to a more recent release and version.*

1. Issue the following command to create the custom resource.

    ```bash
    cd ~/project/operator-driven/git-projects/discovery/

    # STUDENT=$(cat ~/student.txt)
    # INGRESS_FQDN=$STUDENT.gelsandbox.aks.unx.sas.com

    echo $INGRESS_FQDN

    bash -c "cat << EOF > ~/project/operator-driven/git-projects/discovery/discovery-url-sasdeployment.yaml
    apiVersion: orchestration.sas.com/v1alpha1
    kind: SASDeployment
    metadata:
      annotations:
        environment.orchestration.sas.com/readOnlyRootFilesystem: \"false\"
        operator.sas.com/checksum: \"\"
      name: discovery-sasdeployment
    spec:
      cadenceName: \"stable\"
      cadenceVersion: \"2020.1.4\"
      cadenceRelease: \"20210406.1617742339205\"
      repositoryWarehouse:
        url: https://ses.sas.download/ses           ## this is the default value
        updatePolicy: Never                         ## this is the default value. The alternative is 'Releases'
      # The following is an example of using URLs to specify user
      # content, a license, a client certificate, and a CA certiciate.
      userContent:
        # See HashiCorp's Go Getter \"URL Format\" documentation for details:
        #    https://pkg.go.dev/github.com/hashicorp/go-getter@v1.4.1?tab=overview#url-format
        url: git::http://gitlab.${INGRESS_FQDN}/root/discovery.git
      license:
        url: http://gitlab.${INGRESS_FQDN}/root/discovery/-/raw/master/secrets/license/SASViyaV4_license.jwt
      clientCertificate:
        url: http://gitlab.${INGRESS_FQDN}/root/discovery/-/raw/master/secrets/entitlement-certificates/entitlement_certificate.pem
      caCertificate:
        url: http://gitlab.${INGRESS_FQDN}/root/discovery/-/raw/master/secrets/ca-certificates/SAS_CA_Certificate.pem
    EOF"
    ```

1. Following good practice we should push the CR to your Discovery Git project.

    ```sh
    cd ~/project/operator-driven/git-projects/discovery

    PROJECT_URL=http://gitlab.${INGRESS_FQDN}/root/discovery.git

    # Now push the CR file to your Git project
    git add .
    git commit -m "Commit the CR for the Discovery configuration."

    # PUSH the files
    git push $PROJECT_URL
    ```

### Step 4. Deploy GELLDAP to the Discovery namespace

We will use the GEL OpenLDAP (GELLDAP) as the LDAP for user authentication and identities. So we need to set this up first.  We will run the GELLDAP within the Discovery namespace to simplify the connectivity to the GELLDAP instance.

1. Create the discovery namespace.

    ```bash
    kubectl create ns discovery
    ```

1. Deploy GELLDAP into the Discovery namespace using your Git project.

    ```bash
    cd ~/project/operator-driven/git-projects/gelldap2/
    # Set the namespace and deploy
    NS=discovery
    kubectl apply -f gelldap-build.yaml -n ${NS}
    ```

1. Use the following to confirm the pod is running.

    ```sh
    # Confirm that the gelldap pod is running
    kubectl -n ${NS} get all,cm -l app.kubernetes.io/part-of=gelldap
    ```

    You should see output similar to the following.

    ```log
    NAME                                  READY   STATUS    RESTARTS   AGE
    pod/gelldap-server-5bf7594dd7-xx429   1/1     Running   0          15s

    NAME                      TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)             AGE
    service/gelldap-service   ClusterIP   10.0.145.81    <none>        389/TCP             15s
    service/gelmail-service   ClusterIP   10.0.174.233   <none>        1025/TCP,8025/TCP   15s

    NAME                             READY   UP-TO-DATE   AVAILABLE   AGE
    deployment.apps/gelldap-server   1/1     1            1           15s

    NAME                                        DESIRED   CURRENT   READY   AGE
    replicaset.apps/gelldap-server-5bf7594dd7   1         1         1       15s

    NAME                                 DATA   AGE
    configmap/gelldap-bootstrap-users    1      15s
    configmap/gelldap-memberof-overlay   1      15s
    ```


### Step 5. Apply the CR to deploy the discovery environment

Now apply the CR yaml file to deploy the SAS Viya software.

You could do this using the local copy of the custom resource YAML, using the following command. But **DON'T!**

```sh
kubectl apply -f discovery-url-sasdeployment.yaml -n discovery
```

It would be better to use the custom resource stored in the Git project. This is to illustrate using files that have been placed under version control.

---

![notes](../../../11_Azure_AKS_Deployment/img/Lab_note.png)

Before you can use the `kubectl apply` referencing the files in the Git project we will make the Discovery project "**Public**".

We need to do this as when you created the project using the command-line it was created as a private project by default. Additionally, to simplify the lab exercises we haven't created an SSH key and added it to your GitLab configuration.

Perform the following manual steps to make the Discovery project public.

1. Login to your GitLab instance. Use the following to get the URL and root user password.

    ```sh
    cat ~/urls.md | grep GitLab
    ```

1. Open the project settings.

    ![discovery_settings1](../../../11_Azure_AKS_Deployment/img/discovery_settings.png)

1. Make the project "**Public**" and '**save changes**'.

    ![discovery_settings2](../../../11_Azure_AKS_Deployment/img/discovery_settings2.png)

---

Now that the Discovery project is Public you can proceed with deploying the SAS Viya environment.

4. Deploy the discovery environment.

    ```sh
    # Set the namespace and Git URL
    NS=discovery
    GITLAB_URL=http://gitlab.${INGRESS_FQDN}

    # Issue the apply command using the Git project reference
    kubectl apply -f ${GITLAB_URL}/root/discovery/-/raw/master/discovery-url-sasdeployment.yaml -n ${NS}
    ```

1. Make sure it has worked and that the SASDeployment CR was successfully deployed.

    ```sh
    watch kubectl -n discovery get SASDeployment
    ```

    You should see the state change from PENDING --> RECONCILING --> SUCCEEDED. For example.

    ```log
    NAME                      STATE       CADENCENAME   CADENCEVERSION   CADENCERELEASE           AGE
    discovery-sasdeployment   SUCCEEDED   stable        2020.1.4         20210406.1617742339205   2m15s
    ```

    If it is in a "FAILED" state, then run this command to determine the issue.

    ```sh
    kubectl -n discovery describe SASDeployment
    ```

Otherwise, you can watch the deployment progress using the following command.

```sh
watch kubectl -n discovery get pods -o wide
```

Notice the presence, in that namespace, of a pod called `sas-deployment-operator-reconcile`. If you look at the logs of this pod, you will see the activities performed by it.

### Login to confirm you have a working environment (optional)

Before you proceed you might want to confirm that you have a working environment. Once the environment has started you could logon to confirm the access using one of the LDAP users.

* Username: sasadm
* Password: lnxsas

1. Let's store the URLs in a file, for later use.

    ```sh
    NS=discovery
    DRIVE_URL="https://$(kubectl -n ${NS} get ing sas-drive-app -o custom-columns='hosts:spec.rules[*].host' --no-headers)/SASDrive/"
    EV_URL="https://$(kubectl -n ${NS} get ing sas-drive-app -o custom-columns='hosts:spec.rules[*].host' --no-headers)/SASEnvironmentManager/"
    # Write the URLs to the urls.md file
    printf "\n" | tee -a ~/urls.md
    printf "\n  ************************ $NS URLs ************************" | tee -a ~/urls.md
    printf "\n* [Viya Drive ($NS) URL (HTTP**S**)]( ${DRIVE_URL} )" | tee -a ~/urls.md
    printf "\n* [Viya Environment Manager ($NS) URL (HTTP**S**)]( ${EV_URL} )\n\n" | tee -a ~/urls.md
    ```

1. Login to confirm your access.

    Use the following command to view the stored URLs.

    ```sh
    cat ~/urls.md | grep discovery
    ```

### Step 6. Confirm the version, and check for updates

Earlier, we chose a very specific version of the software (`cadenceRelease: "20210406.1617742339205"`).

So now, we need to confirm that is what we got, and we need to check if by chance there would be any updates available.

1. First, to confirm the version, you can run:

    ```sh
    kubectl -n discovery get cm -o yaml | grep ' SAS_CADENCE'
    ```

1. You should see exactly (pay particular attention to the `_RELEASE` line):

    ```log
    SAS_CADENCE_DISPLAY_NAME: Stable 2020.1.4
    SAS_CADENCE_DISPLAY_SHORT_NAME: Stable
    SAS_CADENCE_DISPLAY_VERSION: 2020.1.4
    SAS_CADENCE_NAME: stable
    SAS_CADENCE_RELEASE: "20210406.1617742339205"
    SAS_CADENCE_VERSION: 2020.1.4
    ```

1. Now, in order to check for updates, we need to use the aptly-named "update-checker".

   Start by locating the Kubernetes cronjob called **update-checker**.

    ```sh
    kubectl -n discovery get cronjobs
    ```

    You should see:

    ```log
    NAME                                 SCHEDULE       SUSPEND   ACTIVE   LAST SCHEDULE   AGE
    sas-backup-purge-job                 15 0 1/1 * ?   False     0        <none>          15h
    sas-deployment-operator-autoupdate   29 12 * * *    False     0        <none>          6h16m
    sas-scheduled-backup-job             0 1 * * 0      False     0        <none>          15h
    sas-update-checker                   0 0 * * 0      False     0        <none>          15h
    ```

1. To create a new Job from this CronJob, execute:

    ```sh
    kubectl -n discovery create job --from=cronjob/sas-update-checker  instant-update-check-001
    ```

1. Review the **Job** and the **Pod**

    ```sh
    kubectl -n discovery get job,pod  -l 'app.kubernetes.io/name=sas-orchestration'
    ```

    You should see:

    ```log
    NAME                                                   COMPLETIONS   DURATION   AGE
    job.batch/instant-update-check-001                     1/1           5s         2m
    job.batch/sas-deployment-operator-reconcile-87e8de19   1/1           2m39s      6h20m
    job.batch/sas-deployment-operator-reconcile-8ad6f7fb   1/1           2m40s      15h

    NAME                                                   READY   STATUS      RESTARTS   AGE
    pod/instant-update-check-001-t9mtj                     0/1     Completed   0          2m
    pod/sas-deployment-operator-reconcile-87e8de19-4rkhj   0/1     Completed   0          6h20m
    pod/sas-deployment-operator-reconcile-8ad6f7fb-tp8d7   0/1     Completed   0          15h
    ```

1. And so now, let's look at the log of the "instant-update-check" pod:

    ```sh
    kubectl -n discovery logs  $(kubectl -n discovery get pods | grep instant | cut -d " " -f 1 )
    ```

   The output is quite large, but you should look at it carefully. It will be similar to this sample output.

    <details>

    <summary>Click to expand, to see the sample output.</summary>

    ```log
    The report command started
    Current time is '2021-05-05T22:43:49Z'
    Deployed release 'stable-2020.1.4-20210406.1617742339205':
        Support level is 'SUPPORTED'
        Support ends '2021-07-21T14:00:00.000Z'
    New release available for deployed version 'stable-2020.1.4': 'stable-2020.1.4-20210505.1620229048452'.
        New content available at: 'stable-2020.1.4-20210505.1620229048452'.
            Different versions:
                'sas-analytics-services' version '1.13.0-20210309.1615322162904' has an available update '1.13.2-20210414.1618427696399'
                'sas-backup-agent' version '2.24.3-20210316.1615901768492' has an available update '2.24.6-20210407.1617792857004'
                'sas-backup-job' version '1.18.2-20210323.1616504867137' has an available update '1.18.3-20210401.1617273571438'
                'sas-cachelocator' version '1.24.5-20210318.1616103911039' has an available update '1.24.6-20210406.1617715328324'
                'sas-cacheserver' version '1.24.5-20210318.1616103881060' has an available update '1.24.6-20210406.1617715295807'
                'sas-cas-control' version '2.4.1-20210304.1614885072841' has an available update '2.4.5-20210405.1617653469642'
                'sas-cas-operator' version '3.2.23-20210309.1615320605476' has an available update '3.2.24-20210414.1618408873485'
                'sas-cas-server' version '1.16.6-20210326.1616795492064' has an available update '1.16.11-20210421.1619014115607'
                'sas-code-debugger' version '2.1.11-20210215.1613415421566' has an available update '2.1.13-20210402.1617386109299'
                'sas-compute' version '1.14.19-20210325.1616679207336' has an available update '1.14.22-20210418.1618749206505'
                'sas-config-init' version '1.6.10-20210312.1615510802609' has an available update '1.6.11-20210503.1620068776084'
                'sas-consul-server' version '1.310005.1-20210310.1615404407333' has an available update '1.310005.2-20210405.1617664394581'
                'sas-data-plans' version '1.23.1-20210302.1614725210974' has an available update '1.23.5-20210406.1617718877266'
                'sas-data-profiles' version '4.34.0-20210302.1614728468176' has an available update '4.34.1-20210406.1617728426916'
                'sas-data-studio-app' version '1.24.6-20210310.1615401382263' has an available update '1.24.14-20210407.1617823823976'
                'sas-db-migrator' version '1.2.3-20210312.1615590860623' has an available update '1.2.4-20210408.1617895499636'
                'sas-deployment-operator' version '1.41.0-20210312.1615582998643' has an available update '1.41.3-20210428.1619651404265'
                'sas-job-execution-app' version '2.19.1-20210311.1615466379861' has an available update '2.19.3-20210407.1617803223272'
                'sas-k8s-common' version '2.13.5-20210322.1616439847387' has an available update '2.13.8-20210414.1618432327352'
                'sas-krb5-proxy' version '1.0.1-20210317.1616006523568' has an available update '1.0.2-20210414.1618425122342'
                'sas-lineage-app' version '2.12.0-20210303.1614811918098' has an available update '2.12.1-20210407.1617808160855'
                'sas-logon-app' version '2.43.1-20210305.1614982778041' has an available update '2.43.6-20210416.1618595762782'
                'sas-model-publish' version '2.30.6-20210310.1615396889324' has an available update '2.30.8-20210427.1619540956586'
                'sas-open-source-config' version '1.28.3-20210315.1615792716625' has an available update '1.28.4-20210330.1617121625641'
                'sas-orchestration' version '1.41.1-20210319.1616121181095' has an available update '1.41.3-20210428.1619651404265'
                'sas-prepull' version '1.4.3-20210318.1616072014686' has an available update '1.4.4-20210419.1618847140884'
                'sas-programming-environment' version '1.15.21-20210326.1616800406785' has an available update '1.15.23-20210416.1618609563168'
                'sas-readiness' version '1.6.0-20210311.1615494587649' has an available update '1.6.1-20210416.1618593053927'
                'sas-restore-job' version '1.18.2-20210323.1616504867137' has an available update '1.18.3-20210401.1617273571438'
                'sas-scheduler' version '3.28.0-20210304.1614892522244' has an available update '3.28.1-20210326.1616783575158'
                'sas-score-definitions' version '2.24.0-20210302.1614706212246' has an available update '2.24.3-20210408.1617906468822'
                'sas-score-execution' version '2.23.0-20210302.1614706428231' has an available update '2.23.3-20210408.1617906608535'
                'sas-transfer' version '2.32.2-20210311.1615473474297' has an available update '2.32.4-20210421.1619027841205'
                'sas-transformations' version '2.25.1-20210302.1614725096216' has an available update '2.25.5-20210406.1617718766580'
    New release available for deployed cadence 'stable': 'stable-2020.1.5-20210505.1620237169526'.
        New content available at: 'stable-2020.1.5-20210505.1620237169526'.
            Different versions:
                'sas-analytics-components' version '20.21.0-20210304.1614869982571' has an available update '20.22.3-20210411.1618136560504'
                'sas-analytics-events' version '1.6.0-20210303.1614804432652' has an available update '1.7.0-20210408.1617909885680'
                'sas-analytics-services' version '1.13.0-20210309.1615322162904' has an available update '1.13.2-20210414.1618427696399'
                'sas-annotations' version '2.12.0-20210305.1614944041393' has an available update '2.13.1-20210408.1617875839639'
                'sas-app-registry' version '1.55.10-20210305.1614966534321' has an available update '1.57.15-20210409.1617963544181'
                'sas-arke' version '1.8.3-20210310.1615411212474' has an available update '1.9.3-20210406.1617718891428'
                'sas-audit' version '1.60.1-20210312.1615562197675' has an available update '1.61.0-20210406.1617720769810'
                'sas-authorization' version '3.34.2-20210310.1615412339711' has an available update '3.35.3-20210413.1618326031678'
                'sas-backup-agent' version '2.24.3-20210316.1615901768492' has an available update '2.25.0-20210410.1618053198693'
                'sas-backup-job' version '1.18.2-20210323.1616504867137' has an available update '1.19.1-20210415.1618501536728'
                'sas-cachelocator' version '1.24.5-20210318.1616103911039' has an available update '1.25.2-20210416.1618534317103'
                'sas-cacheserver' version '1.24.5-20210318.1616103881060' has an available update '1.25.2-20210416.1618534495508'
                'sas-cas-administration' version '1.29.2-20210304.1614887691361' has an available update '1.30.1-20210407.1617818043521'
                'sas-cas-control' version '2.4.1-20210304.1614885072841' has an available update '2.4.5-20210405.1617653469642'
                'sas-cas-operator' version '3.2.23-20210309.1615320605476' has an available update '3.3.20-20210419.1618845902632'
                'sas-cas-server' version '1.16.6-20210326.1616795492064' has an available update '1.17.36-20210419.1618868580047'
                'sas-catalog-services' version '4.11.1-20210308.1615210347472' has an available update '4.13.0-20210407.1617805937704'
                'sas-certframe' version '3.12.4-20210310.1615413864075' has an available update '3.13.8-20210406.1617724576236'
                'sas-code-debugger' version '2.1.11-20210215.1613415421566' has an available update '2.1.13-20210402.1617386109299'
                'sas-comments' version '2.60.0-20210309.1615277703539' has an available update '2.61.0-20210409.1617977727358'
                'sas-commonfiles' version '1.0.7-20210331.1617232143874' has an available update '1.1.9-20210419.1618851058873'
                'sas-compute' version '1.14.19-20210325.1616679207336' has an available update '1.15.1-20210416.1618599907572'
                'sas-config-init' version '1.6.10-20210312.1615510802609' has an available update '1.6.11-20210503.1620068776084'
                'sas-config-reconciler' version '1.6.1-20210305.1614954838163' has an available update '1.7.0-20210409.1618007671053'
                'sas-configuration' version '1.62.0-20210309.1615317988666' has an available update '1.63.0-20210409.1618001501712'
                'sas-consul-server' version '1.310005.1-20210310.1615404407333' has an available update '1.310005.2-20210405.1617664394581'
                'sas-conversation-designer-app' version '2.2.1-20210314.1615687376180' has an available update '2.4.6-20210412.1618251378849'
                'sas-credentials' version '1.29.0-20210305.1614957147923' has an available update '1.30.1-20210413.1618326618253'
                'sas-crossdomainproxy' version '1.15.1-20210302.1614705346645' has an available update '1.16.2-20210408.1617896965651'
                'sas-crunchy-data-operator-api-server' version '20.6.1-20210324.1616614042834' has an available update '20.7.0-20210405.1617627932781'
                'sas-crunchy-data-postgres-operator' version '20.9.5-20210318.1616076036914' has an available update '20.10.0-20210406.1617736150985'
                'sas-data-explorer-app' version '1.25.2-20210303.1614797282819' has an available update '1.26.0-20210406.1617720570935'
                'sas-data-flows' version '1.10.0-20210303.1614807803071' has an available update '1.13.0-20210414.1618435088215'
                'sas-data-mining-models' version '39.14.0-20210308.1615219395547' has an available update '39.15.5-20210414.1618429666294'
                'sas-data-mining-project-settings' version '39.12.0-20210308.1615221338764' has an available update '39.13.4-20210406.1617721655096'
                'sas-data-mining-results' version '22.28.0-20210308.1615221944652' has an available update '22.29.5-20210406.1617721643685'
                'sas-data-mining-services' version '39.26.25-20210310.1615412195092' has an available update '39.30.27-20210414.1618396623961'
                'sas-data-plans' version '1.23.1-20210302.1614725210974' has an available update '1.23.5-20210406.1617718877266'
                'sas-data-profiles' version '4.34.0-20210302.1614728468176' has an available update '4.34.1-20210406.1617728426916'
                'sas-data-server-utility' version '20.10.5-20210319.1616161247337' has an available update '20.11.1-20210408.1617844217390'
                'sas-data-sources' version '3.35.0-20210303.1614787453902' has an available update '3.36.0-20210407.1617805905247'
                'sas-data-studio-app' version '1.24.6-20210310.1615401382263' has an available update '1.24.14-20210407.1617823823976'
                'sas-db-migrator' version '1.2.3-20210312.1615590860623' has an available update '1.2.4-20210408.1617895499636'
                'sas-deployment-data' version '1.5.1-20210311.1615501649124' has an available update '1.6.0-20210412.1618249972381'
                'sas-deployment-operator' version '1.41.0-20210312.1615582998643' has an available update '1.45.1-20210429.1619740634080'
                'sas-device-management' version '2.46.0-20210309.1615268644823' has an available update '2.53.0-20210409.1617943377173'
                'sas-drive-app' version '3.19.1-20210310.1615364293189' has an available update '3.23.5-20210414.1618384776894'
                'sas-environment-manager-app' version '4.13.16-20210316.1615870797521' has an available update '4.16.18-20210414.1618431306656'
                'sas-feature-flags' version '1.0.0-20210305.1614980316272' has an available update '1.2.22-20210409.1617965810945'
                'sas-files' version '2.42.3-20210318.1616063551156' has an available update '2.44.0-20210415.1618486051181'
                'sas-folders' version '2.60.1-20210309.1615298410778' has an available update '2.61.2-20210409.1617979326244'
                'sas-fonts' version '1.101.0-20210309.1615279369197' has an available update '1.109.0-20210409.1617954063443'
                'sas-geo-enrichment' version '1.21.0-20210304.1614827769190' has an available update '1.22.1-20210407.1617817722183'
                'sas-gpu-server' version '0.11.22-20210316.1615904419061' has an available update '0.12.31-20210419.1618827997271'
                'sas-graph-builder-app' version '1.80.0-20210309.1615308674461' has an available update '1.87.0-20210412.1618240606159'
                'sas-graph-templates' version '1.95.0-20210309.1615281458778' has an available update '1.101.0-20210413.1618301838568'
                'sas-identities' version '2.42.1-20210304.1614892395214' has an available update '2.43.1-20210413.1618327631242'
                'sas-import-9' version '1.12.39-20210312.1615563067954' has an available update '1.14.40-20210412.1618216628116'
                'sas-information-catalog-app' version '1.4.2-20210312.1615575645877' has an available update '1.6.0-20210407.1617807707115'
                'sas-job-execution' version '2.30.2-20210311.1615494455381' has an available update '2.31.1-20210413.1618328183448'
                'sas-job-execution-app' version '2.19.1-20210311.1615466379861' has an available update '2.19.3-20210407.1617803223272'
                'sas-k8s-common' version '2.13.5-20210322.1616439847387' has an available update '2.16.5-20210428.1619574503181'
                'sas-krb5-proxy' version '1.0.1-20210317.1616006523568' has an available update '1.0.2-20210414.1618425122342'
                'sas-launcher' version '1.25.11-20210322.1616441352568' has an available update '1.26.3-20210412.1618234113254'
                'sas-lineage-app' version '2.12.0-20210303.1614811918098' has an available update '2.12.1-20210407.1617808160855'
                'sas-links' version '1.111.0-20210309.1615285306337' has an available update '1.121.0-20210413.1618305565231'
                'sas-localization' version '1.13.10-20210317.1616019118285' has an available update '1.15.34-20210504.1620113208179'
                'sas-logon-app' version '2.43.1-20210305.1614982778041' has an available update '2.44.4-20210419.1618836339613'
                'sas-mail' version '1.59.0-20210304.1614866752667' has an available update '1.60.0-20210408.1617905036149'
                'sas-maps' version '1.118.0-20210309.1615285797078' has an available update '1.132.0-20210414.1618392371245'
                'sas-ml-pipeline-automation' version '39.26.0-20210308.1615222182668' has an available update '39.27.7-20210414.1618408485342'
                'sas-model-publish' version '2.30.6-20210310.1615396889324' has an available update '2.32.3-20210414.1618370149646'
                'sas-model-repository' version '3.17.44-20210310.1615414712160' has an available update '3.18.76-20210416.1618608008242'
                'sas-model-studio-app' version '1.77.2-20210308.1615241926715' has an available update '1.90.0-20210409.1618000712671'
                'sas-natural-language-conversations' version '1.6.2-20210312.1615572243715' has an available update '1.7.1-20210409.1617973667898'
                'sas-natural-language-generation' version '1.9.2-20210311.1615424130725' has an available update '1.10.0-20210408.1617850497269'
                'sas-natural-language-understanding' version '3.7.1-20210311.1615424640957' has an available update '3.8.0-20210408.1617851000870'
                'sas-notifications' version '1.57.0-20210304.1614874332460' has an available update '1.58.1-20210419.1618840002404'
                'sas-office-addin-app' version '1.0.3-20210309.1615326446371' has an available update '1.3.0-20210409.1618001987366'
                'sas-open-source-config' version '1.28.3-20210315.1615792716625' has an available update '1.30.3-20210419.1618838665008'
                'sas-opendistro' version '7.1.5-20210211.1613036266957' has an available update '7.2.0-20210312.1615562152650'
                'sas-opendistro-operator' version '7.3.2-20210215.1613407804534' has an available update '7.5.1-20210413.1618337290110'
                'sas-opendistro-sysctl' version '1.0.1-20210127.1611745617060' has an available update '1.1.0-20210223.1614095823287'
                'sas-orchestration' version '1.41.1-20210319.1616121181095' has an available update '1.45.1-20210429.1619740634080'
                'sas-preferences' version '1.60.0-20210304.1614872848839' has an available update '1.61.0-20210407.1617808932263'
                'sas-prepull' version '1.4.3-20210318.1616072014686' has an available update '1.4.4-20210419.1618847140884'
                'sas-programming-environment' version '1.15.21-20210326.1616800406785' has an available update '1.16.40-20210419.1618854486669'
                'sas-projects' version '1.24.0-20210304.1614827766151' has an available update '1.25.1-20210407.1617817726903'
                'sas-rabbitmq-server' version '3.811002.4-20210311.1615424395048' has an available update '3.811003.0-20210325.1616687476265'
                'sas-readiness' version '1.6.0-20210311.1615494587649' has an available update '1.6.1-20210416.1618593053927'
                'sas-report-distribution' version '2.59.20-20210305.1614965817133' has an available update '2.61.16-20210409.1617964444333'
                'sas-report-execution' version '2.40.1-20210310.1615393273597' has an available update '2.55.3-20210416.1618596290386'
                'sas-report-renderer' version '1.109.2-20210311.1615484644731' has an available update '1.119.0-20210409.1617942639718'
                'sas-report-services-group' version '4.21.1-20210309.1615271474277' has an available update '4.24.19-20210408.1617896057991'
                'sas-restore-job' version '1.18.2-20210323.1616504867137' has an available update '1.19.1-20210415.1618501536728'
                'sas-scheduler' version '3.28.0-20210304.1614892522244' has an available update '3.29.1-20210413.1618329348214'
                'sas-score-definitions' version '2.24.0-20210302.1614706212246' has an available update '2.24.3-20210408.1617906468822'
                'sas-score-execution' version '2.23.0-20210302.1614706428231' has an available update '2.23.3-20210408.1617906608535'
                'sas-search' version '2.31.0-20210308.1615187692376' has an available update '2.33.4-20210430.1619822804833'
                'sas-studio-app' version '6.194.0-20210310.1615417191796' has an available update '6.273.18-20210414.1618431798454'
                'sas-templates' version '1.25.3-20210305.1614981054605' has an available update '1.26.1-20210413.1618330722420'
                'sas-theme-content' version '1.26.1-20210302.1614708933048' has an available update '1.27.1-20210405.1617656460785'
                'sas-theme-designer-app' version '3.28.4-20210304.1614867851095' has an available update '3.29.2-20210405.1617656702054'
                'sas-themes' version '3.26.8-20210304.1614866754645' has an available update '3.27.3-20210405.1617658149689'
                'sas-thumbnails' version '1.57.11-20210305.1614965909127' has an available update '1.59.14-20210409.1617965229325'
                'sas-transfer' version '2.32.2-20210311.1615473474297' has an available update '2.33.5-20210415.1618514077087'
                'sas-transformations' version '2.25.1-20210302.1614725096216' has an available update '2.25.5-20210406.1617718766580'
                'sas-types' version '3.18.0-20210304.1614872703827' has an available update '3.19.0-20210407.1617810275517'
                'sas-unleash' version '0.0.4-20210201.1612191499704' has an available update '1.0.1-20210326.1616769115962'
                'sas-visual-analytics' version '0.2.4-20210306.1615001539181' has an available update '0.5.57-20210412.1618249259792'
                'sas-visual-analytics-administration' version '1.59.17-20210305.1614965825081' has an available update '1.61.15-20210409.1617964910556'
                'sas-visual-analytics-app' version '2.59.1-20210311.1615476181166' has an available update '2.60.31-20210414.1618417958502'
                'sas-web-data-access' version '1.21.0-20210304.1614827728750' has an available update '1.22.1-20210407.1617817763289'
    The report command completed successfully
    ```

    </details>

   As you can hopefully see from the output above, we have 2 choices:

    * Within `stable-2020.1.4` there are updates (think of it as hotfixes)
    * There is also a new Version available called `stable-2020.1.5`

*Note that by the time you read this, there might more stable versions available than just `2020.1.5`*

### Step 7. Apply hotfixes within the version

Although we could jump straight to the next version, we will do it in 2 steps to illustrate the process better.

1. Let's replace "Never" with "Releases" in the CR definition, and remove the fixed cadenceRelease. This will get the latest updates for Stable 2020.1.4.

    ```bash
    cd ~/project/operator-driven/git-projects/discovery
    cp discovery-url-sasdeployment.yaml discovery-url-sasdeployment.yaml.never
    sed -i 's/Never/Releases/g' discovery-url-sasdeployment.yaml
    # Remove the cadenceRelease
    sed -i 's/20210406.1617742339205//g' discovery-url-sasdeployment.yaml
    # Confirm the changes
    icdiff  discovery-url-sasdeployment.yaml.never discovery-url-sasdeployment.yaml
    ```

1. And now, let's apply the CR:

    ```sh
    kubectl apply -f discovery-url-sasdeployment.yaml -n discovery

    ```

1. Wait for things to "kick in":

   * The operator pod (in the sas-operator namespace) will activate (check its log).
   * In the discovery namespace , a new "sas-deployment-operator-reconcile" pod will start up. If you check its log you will see it build and apply your manifest.
   * Once that happens, you will see a lot of new pods starting up. They will "double-up" a lot of the deployments.
   * As the new pods come fully online, the old ones will eventually disappear.

   To see the pods restarting you can use the following command: `watch kubectl get pods -n discovery`. But you could use the following filter to get a shorter list: `watch 'kubectl get pods -n discovery | grep Init'`.

   A better way to watch the deployment progress is using the following command:
   `watch 'kubectl -n discovery get pods --sort-by=.status.startTime -o wide | tac'`

   It may take a few minutes before you start to see the pods being replaced.

1. Congratulations! You've just applied all the hotfixes for **stable-2020.1.4**.

1. To confirm this, re-run the update checker as we did earlier.

    ```sh
    # Delete and create the job to capture the changes
    kubectl -n discovery delete job instant-update-check-001
    kubectl -n discovery create job --from=cronjob/sas-update-checker instant-update-check-001

    # You should see messages confirming that the job was deleted and created

    # Display the log
    kubectl -n discovery logs  $(kubectl -n discovery get pods | grep instant | cut -d " " -f 1 )
    ```

   You should now see the following message in the log.

   **No new release available for deployed version 'stable-2020.1.4'**.

### Review the deployment

The following diagram provides an overview of the deployment exercise.

![Git-overview](/06_Deployment_Steps/img/Deployment_1.png)

1. Issue the kubectl apply for the Custom Resource (CR)

1. The operator watches for CR changes and this triggers the Discovery deployment.

1. The operator reads the source files described in the CR from the Git project.

1. The operator deploys the Discovery environment.

As you can see using the operator does simplify the deployment steps, as you don't have to build the manifest file and apply it. But you still need to edit / provide yaml files for the SAS Viya configurations.

---

## Upgrade a Viya environment using the Operator

Now that you have a running Viya environment, the Discovery environment, you can use the operator to upgrade to a new Stable version. For the initial deployment you used Stable 2020.1.4, and it's now up to date.

You could check this by logging onto the Viya environment, but an easier way is to issue the following command to confirm the version and cadence being used.

* Issue the following command to confirm the cadence and version details.

    ```sh
    kubectl -n discovery get cm -o yaml | grep ' SAS_CADENCE'
    ```

* You should see output similar to the following, but your SAS_CADENCE_RELEASE information will be different (potentially higher).

    ```log
    SAS_CADENCE_DISPLAY_NAME: Stable 2020.1.4
    SAS_CADENCE_DISPLAY_SHORT_NAME: Stable
    SAS_CADENCE_DISPLAY_VERSION: 2020.1.4
    SAS_CADENCE_NAME: stable
    SAS_CADENCE_RELEASE: "20210528.1622168558776"
    SAS_CADENCE_VERSION: 2020.1.4
    ```

### Upgrade to 2020.1.5

The good news is that upgrading the environment using the operator is very easy. The operator will pull the required assets and images based on the version info in the CR.

#### Step 1. Edit the CR, specify the new cadence version

1. Create a new Custom Resource file to work with.

    ```bash
    # Copy the existing file to rename it.
    cd ~/project/operator-driven/git-projects/discovery/
    cp discovery-url-sasdeployment.yaml discovery-url-sasdeployment.yaml.2020.1.4
    ```

1. Edit the discovery-upgrade-yaml file to update the cadence version (cadenceVersion) to 2020.1.4. Remember to ensure that the double quotes are there.

   You can use VI to do this or run the following command to edit the file.

    ```bash
    cd ~/project/operator-driven/git-projects/discovery/
    # Update the cadence version
    sed -i 's/2020.1.4/2020.1.5/' discovery-url-sasdeployment.yaml
    # Confirm the change has been made
    icdiff discovery-url-sasdeployment.yaml.2020.1.4 discovery-url-sasdeployment.yaml
    ```

#### Step 2. Upgrade the Discovery environment

You now need to apply the updated yaml file.

1. First you need to push the updates to the Git project.

    ```sh
    cd ~/project/operator-driven/git-projects/discovery

    PROJECT_URL=http://gitlab.${INGRESS_FQDN}/root/discovery.git

    # Now push the updated CR file to your Git project
    git add .
    git commit -m "Update to specify Stable 2020.1.5"

    # PUSH the files
    git push $PROJECT_URL
    ```

1. Issue the following command to upgrade to the Discovery environment.

    ```sh
    # Set the namespace and Git URL
    NS=discovery
    GITLAB_URL=http://gitlab.${INGRESS_FQDN}

    # Issue the apply command using the Git project reference
    kubectl apply -f ${GITLAB_URL}/root/discovery/-/raw/master/discovery-url-sasdeployment.yaml -n ${NS}
    ```

    You can watch the deployment progress using the following command. It may take a few minutes before you start to see the pods being replaced.

    ```sh
    watch 'kubectl -n discovery get pods --sort-by=.status.startTime -o wide | tac'
    ```

    You should see a `sas-deployment-operator-reconcile` pod is created, once the reconcilation process has completed you will see the Viya pods being refreshed.

    Alternatively, you can use the 'gel_OKViya4' command to confirm if SAS Viya is ready.

    ```sh
    # Set the namesape to discovery
    NS=discovery
    time gel_OKViya4 -n ${NS} --wait -ps
    ```

    This will display the current status of your environment and will keep cycling until 90% of your endpoints are working.
    This can take between 15 minutes and 40 minutes for a fresh deployment.

1. While this is happening, you should try to use/access your environment to see how usable it is during this update.

1. Confirm the cadence version has been updated.

    ```sh
    kubectl -n discovery get cm -o yaml | grep ' SAS_CADENCE'
    ```

    You should now see output similar to the following.

    ```log
    SAS_CADENCE_DISPLAY_NAME: Stable 2020.1.5
    SAS_CADENCE_DISPLAY_SHORT_NAME: Stable
    SAS_CADENCE_DISPLAY_VERSION: 2020.1.5
    SAS_CADENCE_NAME: stable
    SAS_CADENCE_RELEASE: "20210528.1622168558778"
    SAS_CADENCE_VERSION: 2020.1.5
    ```

**Congratulations!** You have just upgraded your SAS Viya deployment (environment).

#### Final steps

* Once everything has rolled over, you should look at your pods , sort by age.

    ```sh
    kubectl -n discovery get pods --sort-by=.status.startTime | tac
    ```

You will see that although many of the pods have been replaced by newer ones, there are some that never got replaced and are older than the rest.

It could be normal: This could be due to the fact that their **image** remained the same from one version to the next.

However, when it comes to CAS, this is a known "feature". You have to restart CAS (delete its pods), when you are ready for it to restart. If you don't CAS will keep on running from the same old images.

Our recommendation is to **always** restart CAS right away.

---

## Making an admin change using the SAS Viya Deployment Operator

There are many reasons to make a change to the Viya environment, the most common is some form of administration or configuration change. For example, changing from running CAS in SMP mode to MPP mode.

This is the type of change that needs the annotation that we added to the custom resource (`operator.sas.com/checksum: ""`).

### Make a change to the deployment

In this exercise you will update the CAS Server. When we deployed the Discovery environment, we deployed an SMP CAS Server.

Now let's changing that to an MPP CAS Server with 4 workers and a secondary controller.

1. First create 2 files, the definition for the secondary controller and the second to define the number of CAS Workers.

    ```bash
    # Create cas-default_secondary_controller.yaml
    bash -c "cat << EOF > ~/project/operator-driven/git-projects/discovery/site-config/cas-default_secondary_controller.yaml
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

    # Create cas-default_workers.yaml
    bash -c "cat << EOF > ~/project/operator-driven/git-projects/discovery/site-config/cas-default_workers.yaml
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

1. Now you need to update the kustomization.yaml to reference them.

    ```bash
    ansible localhost \
        -m lineinfile \
        -a  "dest=~/project/operator-driven/git-projects/discovery/kustomization.yaml \
            insertafter='phase\-1' \
            line='  - site-config/cas-default_secondary_controller.yaml\n  - site-config/cas-default_workers.yaml' \
            state=present \
            backup=yes " \
            --diff
    ```

1. Great, now that this is done, we need to commit all this and push to Gitlab.

    ```sh
    cd ~/project/operator-driven/git-projects/discovery

    PROJECT_URL=http://gitlab.${INGRESS_FQDN}/root/discovery.git

    # Now push the updated CR file to your Git project
    git add .
    git commit -m "We are making changes to get an MPP CAS Server"

    # PUSH the files
    git push $PROJECT_URL
    ```

1. Once that is done, open up the Gitlab page to see your commit.

    ```sh
    cat ~/urls.md | grep gitlab
    ```

### Applying the change to the environment

Now, you might have thought that this (committing to git and pushing to gitlab) would be enough. It is not.

If you check your pods, you will see that CAS configuration has not changed.

So, you might think that you need to re-apply the CR definition of your SAS deployment. You would be right!

Remember you added the annotation (`operator.sas.com/checksum: ""`) to the CR when it was created, we need this for this type of change as the CR definition has not changed.

* Run the following to apply the changes.

    ```sh
    # Set the namespace and Git URL
    NS=discovery
    GITLAB_URL=http://gitlab.${INGRESS_FQDN}

    # Issue the apply command using the Git project reference
    kubectl apply -f ${GITLAB_URL}/root/discovery/-/raw/master/discovery-url-sasdeployment.yaml -n ${NS}
    ```

It will take a few minutes to see any changes, but you can use the following command to watch the CAS pods: `watch 'kubectl get pods -n discovery -o wide | grep cas'`

If you wait long enough you should eventually see that there are 6 cas nodes. For example, *aks-cas-30181712-vmss000000* ... *aks-cas-30181712-vmss000005*.

## Next Steps

Now that you have completed the exercise using a Git repository with the Deployment Operator, in the next exercise you will use the operator with an inline configuration.

Click [here](./11_320_Using_an_inline_configuration.md) to move onto the next exercise: ***11_320_Using_an_inline_configuration.md***

### Table of Contents for the Deployment Operator exercises

<!--Navigation for this set of labs-->
* [11 100 Creating an AKS Cluster](../11_100_Creating_an_AKS_Cluster.md)
* [11 110 Performing Prereqs in AKS](../11_110_Performing_the_prerequisites.md)
* [11 300 Deployment Operator environment set-up](./11_300_Deployment_Operator_environment_set-up.md)
* [11 310 Using the Deployment Operator with a Git Repository](./11_310_Using_the_DO_with_a_Git_Repository.md) **<-- You are here**
* [11 320 Using the Deployment Operator with an inline configuration](./11_320_Using_an_inline_configuration.md)
* [11 330 Using the Orchestration Tool to create the SASDeployment Custom Resource](./11_330_Using_the_Orchestration_Tool.md)

## Navigation

