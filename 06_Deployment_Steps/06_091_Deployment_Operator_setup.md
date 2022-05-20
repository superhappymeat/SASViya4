![Global Enablement & Learning](https://gelgitlab.race.sas.com/GEL/utilities/writing-content-in-markdown/-/raw/master/img/gel_banner_logo_tech-partners.jpg)

# Deployment Operator environment set-up

* [Introduction](#introduction)
  * [File system structure for the lab exercises](#file-system-structure-for-the-lab-exercises)
* [Prep the nodes](#prep-the-nodes)
* [Installation and set-up of GitLab](#installation-and-set-up-of-gitlab)
  * [Using Helm to install a GitLab Server](#using-helm-to-install-a-gitlab-server)
  * [Create the required Git projects](#create-the-required-git-projects)
  * [Clone the projects to the Linux server](#clone-the-projects-to-the-linux-server)
* [Set-up and deploy GELLDAP](#set-up-and-deploy-gelldap)
* [Deploying the SAS Viya Deployment Operator](#deploying-the-sas-viya-deployment-operator)
  * [Create the working directory](#create-the-working-directory)
  * [Copy the Assets and Extract](#copy-the-assets-and-extract)
  * [Deploy the SAS Viya Deployment Operator](#deploy-the-sas-viya-deployment-operator)
    * [Step 1. Edit the transformer.yaml](#step-1-edit-the-transformeryaml)
    * [Step 2. Edit kustomization.yaml for cluster-wide scope](#step-2-edit-kustomizationyaml-for-cluster-wide-scope)
    * [Step 3. Build and Apply the manifests](#step-3-build-and-apply-the-manifests)
  * [Checking the deployment (optional)](#checking-the-deployment-optional)
* [Next Steps](#next-steps)
* [Navigation](#navigation)

## Introduction

This lab contains a set of exercises to provide experience with using the SAS Viya Deployment Operator.

The SAS Viya Deployment Operator watches the cluster for a Custom Resource (CR) of the `Kind: SASDeployment`. The data in the SASDeployment custom resource is used by the operator when installing SAS Viya.

The operator can run in two modes:

* *"Namespace"* mode:
  * A long-lived pod inside the Viya namespace
* *"Cluster-wide"* mode
  * A long-lived pod in its own namespace, separate from the Viya namespace(s).

This is illustrated below.

![overview](/06_Deployment_Steps/img/Deployment_operator_structure.png)

In this set of exercises you will use the operator in cluster-wide mode. The advantage of using the operator in cluster-wide mode is that you can delete the Viya namespace without deleting (killing) the operator.

### File system structure for the lab exercises

Before you start the lab exercises let's take a moment to discuss the file system structure that will be used. To date for the other exercises you have been using the `~/project/deploy/` folder.

For this set of exercises you will use the structure shown in the image below.

![folders](/06_Deployment_Steps/img/Folders-v2.png)

* The `/operator-setup` folder is the root folder for the configuration files for the deployment operator itself. We recommend organising the files by cadence version of the operator being used. For example, stable-202x.y.z or lts-202x.y.
* The `/operator-driven` folder is the root folder for the Viya environment(s) kustomisation and input files.
* When using the deployment operator there are two possible ways of providing the input files:
  1. Storing them in a **git** repository
  1. Passing them as **inline** content in a YAML file
  * Hence, the '**git-projects**' and '**inline-projects**' folders.
* Although both methods will be covered, the **git** method is likely to be better and easier than the alternative, and so that is the first one we'll cover.

## Prep the nodes

Before you proceed, the first step is to clean-up and prep the cluster. For this you will do the following:

1. Delete any existing Viya deployments to free up space. For this set of exercises we need to make sure that the 'lab' namespaces has been cleaned up.

    ```bash
    # delete the lab namespace
    kubectl delete ns lab
    ```

1. Use the following commands to remove any existing labels and taints from the nodes.

    ```bash
    kubectl label nodes intnode01 intnode02 intnode03 intnode04 intnode05 workload.sas.com/class-  --overwrite
    kubectl taint nodes intnode01 intnode02 intnode03 intnode04 intnode05 workload.sas.com/class-  --overwrite
    ```

1. Assign the node labels.

    ```bash
    # Label the nodes
    kubectl label nodes intnode01           workload.sas.com/class=stateful   --overwrite
    kubectl label nodes intnode02 intnode03 workload.sas.com/class=stateless  --overwrite
    kubectl label nodes intnode04           workload.sas.com/class=cas        --overwrite
    kubectl label nodes intnode05           workload.sas.com/class=compute    --overwrite
    ```

1. Taint intnode04 for the CAS pods.

    ```bash
    kubectl taint nodes intnode04 workload.sas.com/class=cas:NoSchedule --overwrite
    ```

It's possible that some pods could have started on intnode04 before we assigned the taints.

Software such as cert-manager and the monitoring suite was auto-installed in kubernetes for you. Some of these pods may have ended up on intnode04, which we need to keep clear for CAS!

If so, they are still running on intnode04, and might take up too much space, therefore preventing the CAS pod from starting on it.

If you want to see if there are pods running on intnode04 use the following command `kubectl get pods -A -o wide | grep intnode04`

If this is the case, we need to:

* Cordon the node
* Drain it
* Un-cordon it

This is what the following commands will do for you.

5. Issue the following commands.

    ```bash
    # Cordon the node so that no new pods come to it
    kubectl cordon intnode04

    # Now we drain away all the pods from it
    kubectl drain  intnode04 --ignore-daemonsets --delete-local-data

    # Check that the node is empty now
    kubectl get pods -A -o wide | grep intnode04

    # You now need to un-cordon the node so that future pods can come to it!
    kubectl uncordon intnode04
    ```

You are now ready to start installing the applications and SAS Viya.

## Installation and set-up of GitLab

As a good practice you can, or should, use Git to version control all the input and configuration files used to deploy a SAS Viya environment, even if you're not using the Deployment Operator.

To illustrate this we will create a Git project for a GELLDAP configuration backup and to store the SAS environments. We will also store the order secrets under the Viya environment project.

In preparation for the first deployment exercise you will now setup a Git repository in your cluster. You would likely not do that at a customer, and instead use one of their existing Version Control system.

### Using Helm to install a GitLab Server

<!--

We will use a modified version of the steps detailed in [Deploying Gitlab in Kubernetes](https://gitlab.sas.com/GEL/workshops/PSGEL255-deploying-viya-4.0.1-on-kubernetes/-/blob/feature/do/06_Deployment_Steps/06_241_Deploying_gitlab.md).
 -->

1. The following command will "prepull" a lot of the gitlab images onto your nodes. This helps avoid issues with dockerhub pull rate limits.

    ```bash
    # define the prepullit function
    source <( curl -k -s https://gelgitlab.race.sas.com/GEL/utilities/gellow/-/raw/validation/scripts/common/common_functions.shinc)

    prepullit sasnodes busybox:latest
    prepullit sasnodes bitnami/postgres-exporter:0.8.0-debian-10-r99
    prepullit sasnodes bitnami/postgresql:11.9.0
    prepullit sasnodes bitnami/redis:6.0.9-debian-10-r0
    prepullit sasnodes bitnami/redis-exporter:1.12.1-debian-10-r11
    prepullit sasnodes gitlab/gitlab-runner:alpine-v13.9.0
    prepullit sasnodes jimmidyson/configmap-reload:v0.3.0
    prepullit sasnodes minio/mc:RELEASE.2018-07-13T00-53-22Z
    prepullit sasnodes minio/minio:RELEASE.2017-12-28T01-21-00Z

    ```

1. Create the namespace for GitLab (we will clean-up any existing namespace).

   ```bash
   kubectl delete ns gitlab
   kubectl create ns gitlab
   ```

1. Use Helm to deploy GitLab. First, update the helm repo.

    ```bash
    ## the Helm repo for gitlab:
    helm repo add gitlab https://charts.gitlab.io/

    ## update its content
    helm repo update

    ## check out the versions that are available
    helm search repo -l gitlab/gitlab
    ```

1. Then, create the Vars file for helm install of gitlab

    ```bash
    tee /tmp/minigitlab.values.yaml > /dev/null <<EOF
    ---
    postgresql:
        image:
            repository: gelharbor.race.sas.com/dockerhubstaticcache/bitnami/postgresql
            tag: 11.9.0
        metrics:
            enabled: false
    prometheus:
        install: false
    global:
        edition: ce
        minio:
            enabled: true
            image: gelharbor.race.sas.com/dockerhubstaticcache/minio/minio
            imageTag: RELEASE.2017-12-28T01-21-00Z
            minioMc:
                image: gelharbor.race.sas.com/dockerhubstaticcache/minio/mc
            minioMc:
                tag: RELEASE.2018-07-13T00-53-22Z
        hosts:
            domain: devops.$(hostname -f)
            https: true
            gitlab:
                name: gitlab.devops.$(hostname -f)
                https: false
        ingress:
            enabled: true
            class: nginx
            tls:
                enabled: false
        busybox:
            image:
                repository: gelharbor.race.sas.com/dockerhubstaticcache/busybox
                tag: latest
    redis:
        image:
            registry: gelharbor.race.sas.com
            repository: dockerhubstaticcache/bitnami/redis
            tag: 6.0.9-debian-10-r0
    minio:
        image: gelharbor.race.sas.com/dockerhubstaticcache/minio/minio
        imageTag: RELEASE.2017-12-28T01-21-00Z
        minioMc:
            image: gelharbor.race.sas.com/dockerhubstaticcache/minio/mc
            tag: RELEASE.2018-07-13T00-53-22Z
    nginx-ingress:
        enabled: false
    certmanager-issuer:
        email: email@example.com
    registry:
        enabled: false
    EOF

    # this option seems flawed at the moment. we'll have to rely on pre-pull until we figure it out.
    #helm upgrade --install \
    #    gitlab gitlab/gitlab \
    #    --timeout 1200s \
    #    --namespace gitlab \
    #    --version v4.10.2 \
    #    --values /tmp/minigitlab.values.yaml

   helm install gitlab gitlab/gitlab \
       --timeout 600s \
       --set global.hosts.domain=devops.$(hostname -f) \
       --set global.hosts.https=false \
       --set certmanager-issuer.email=me@example.com \
       --set global.edition=ce \
       --set nginx-ingress.enabled=false \
       --set global.ingress.enabled=true \
       --set global.ingress.class=nginx \
       --set global.ingress.tls.enabled=false \
       --namespace gitlab \
       --version v4.10.2


    ## in case we missed images, this will prepull them:
    source <( curl -k -s https://gelgitlab.race.sas.com/GEL/utilities/gellow/-/raw/validation/scripts/common/common_functions.shinc)
    prepullns gitlab


    #kubectl wait -n gitlab --for=condition=ready  --all pods --timeout 400s


   ```

   This will take between about 5-6 minutes to be ready.

   *You want all the pods to be running before moving onto the next steps. Use `kubectl -n gitlab get pods` to check the status.*

   <details>
     <summary>Click to expand to see the GitLab pod status when the GitLab deployment is running.</summary>

     ```log
     NAME                                          READY   STATUS
     gitlab-cainjector-67dbdcc896-8gqsg            1/1     Running
     gitlab-cert-manager-69bd6d746f-7fffn          1/1     Running
     gitlab-gitaly-0                               1/1     Running
     gitlab-gitlab-exporter-99dcfdcdf-5hnxl        1/1     Running
     gitlab-gitlab-runner-76bc87589d-5lvkr         1/1     Running
     gitlab-gitlab-shell-7c67698cbd-hxvr9          1/1     Running
     gitlab-gitlab-shell-7c67698cbd-l5b62          1/1     Running
     gitlab-issuer-1-nfbgk                         0/1     Completed
     gitlab-migrations-1-jflhg                     0/1     Completed
     gitlab-minio-56667f8cb4-j9nkd                 1/1     Running
     gitlab-minio-create-buckets-1-kfpvw           0/1     Completed
     gitlab-postgresql-0                           2/2     Running
     gitlab-prometheus-server-768cd8f69-f6cbl      2/2     Running
     gitlab-redis-master-0                         2/2     Running
     gitlab-registry-6475bc7ff6-fxhjf              1/1     Running
     gitlab-registry-6475bc7ff6-sd2px              1/1     Running
     gitlab-sidekiq-all-in-1-v1-74ff4898bb-xjfbf   1/1     Running
     gitlab-task-runner-98f957bc7-2p2t2            1/1     Running
     gitlab-webservice-default-77d7485645-5b4xx    2/2     Running
     gitlab-webservice-default-77d7485645-vrp92    2/2     Running
     ```

   </details>

1. Once GitLab is running, we can query GitLab for the default password for the root account.

    ```bash
    gitlab_root_pw=$(kubectl -n gitlab get secret \
      gitlab-gitlab-initial-root-password \
      -o jsonpath='{.data.password}' | base64 --decode )
    echo $gitlab_root_pw

    printf "\n* [GitLab URL (HTTP)](http://gitlab.devops.$(hostname -f)/ )  (User=root Password=${gitlab_root_pw})\n\n" | tee -a ~/urls.md
    ```

    You should see output similar to the following.

    ```log
    * [GitLab URL (HTTP)](http://gitlab.devops.rext03-0007.race.sas.com/ )  (User=root Password=41PWnXgqL2stk2LjgQRjPmhCAj4kztwNuk8MvFpFvPw0LMskk92tI9HdJ3rFxfrg)
    ```

    You will need this password for the next step to create the user for the exercise ('cloud-user').

### Create the Git user ('cloud-user')

***Note, currently there aren't any cheat-codes to automate these steps. The automation is being developed and will be added at a later stage.***

1. Access GitLab using the URL shown in the previous step (You can 'CTRL-LEFT_Click' to open the URL). It should look similar to the following.

   ```log
   http://gitlab.devops.rext03-0007.race.sas.com/
   ```

1. Logon to git using the default (root user) credentials.

1. Once you have logged in as root, create the 'Cloud User'. You do this via the 'Admin Area'. Navigate to the 'Users' tab and select '**New User**'.

   ![AdminArea](/06_Deployment_Steps/img/Git_register_user.png)

1. Create the cloud-user. As per the screenshot below.

   ![cloud-user](/06_Deployment_Steps/img/create-user.png)

    * Name: Cloud User
    * Username: cloud-user
    * Email: cloud.user@sas.com

    Don't worry to much about the email. In the next step you will use the GitLab administration UI to set the password you will use in the rest of this exercise.

   Select '**Create user**'.

1. Now edit the user to set the password and save the changes.
   ![Edit user](/06_Deployment_Steps/img/create_user2.png)

   * Username: cloud-user
   * Password: **Orion123**

1. Log out of GitLab.

1. Login to Gitlab as the 'Cloud User'

    You may get prompted to set the password on first login with the cloud-user. Set the password as required.

    I used '**Orion1234**'.

    You are now ready to use GitLab to store the project files.

### Create the required Git projects

In this exercise we are going to use the operator to create the **Discovery** environment. To support this we will create a "Discovery' project.

We will also store the GELLDAP files in Git. The instructions below will step you through creating the Discovery and GELLDAP2 projects.

We will create the two project as "Public" projects to simplify the lab instructions. Clearly we would NOT recommend this approach to a customer!

1. Login to GitLab as the cloud-user.

2. Create a new project called 'Discovery'. As per the following screenshot.
   ![create_project](/06_Deployment_Steps/img/create_discovery_project.png)

1. Once the project has been created copy the URL to clone the project and save this for later use. For example, the Discovery project.

   ![project_clone](/06_Deployment_Steps/img/discovery_project_clone.png)


1. Now create a project to backup the GELLDAP configuration. To avoid confusion with the source GELLDAP project, for your local GitLab environment create a project called '**GELLDAP2**'.

   ![gelldap](/06_Deployment_Steps/img/create_gelldap2_project.png)

1. After the GELLDAP2 project has been created save the project URL.

### Clone the projects to the Linux server

Now that you have the project setup and the project URL saved, we need to sync it to the Linux server. For this we will create a folder under the `/projects` directory.

1. Create folder.

   ```bash
   mkdir -p ~/project/operator-driven/git-projects/
   ```

1. Navigate to the folder and tell git to remember your credentials.

   ```bash
   cd ~/project/operator-driven/git-projects
   git config --global credential.helper store
   git config --global http.sslVerify false

   git config --global user.email "cloud.user@sas.com"
   git config --global user.name "Cloud User"
   git config --global user.name "Cloud"
   git config --global user.password "Orion1234"

   ```

1. Clone the Discovery project.

    ```bash
    cd ~/project/operator-driven/git-projects
    # Get host name and set the project URL
    HOST_SUFFIX=$(hostname -f)
    DISCOVERY_URL=http://gitlab.devops.${HOST_SUFFIX}/cloud-user/discovery.git

    # Clone the project
    git clone $DISCOVERY_URL
    ```

1. Clone the GELDAP2 project.

    ```bash
    cd ~/project/operator-driven/git-projects
    # Get host name and set the project URL
    HOST_SUFFIX=$(hostname -f)
    GELLDAP2_URL=http://gitlab.devops.${HOST_SUFFIX}/cloud-user/gelldap2.git

    # Clone the project
    git clone $GELLDAP2_URL
    ```

Note, depending on whether you selected to create the project README file you may see the following warming message: `warning: You appear to have cloned an empty repository.`

This is nothing to worry about.

You should now have two new directories under the `/git-projects` folder.

## Set-up and deploy GELLDAP

In the next set of lab exercises we will use the GEL OpenLDAP (GELLDAP) as the LDAP for user authentication and identities. So we need to set this up first.  We will run the GELLDAP within the Discovery namespace to simplify the connectivity to the GELLDAP instance.

1. Clone the GELLDAP project into the project directory.

   ```bash
   cd ~/project/
   git clone https://gelgitlab.race.sas.com/GEL/utilities/gelldap.git
   cd ~/project/gelldap/
   git fetch --all
   GELLDAP_BRANCH=int_images
   git reset --hard origin/${GELLDAP_BRANCH}
   ```

1. Copy the GELLDAP files to your git (GELLDAP2) project.

   *As we don't want to overwrite the '.git' folder in the GELLDAP2 project, you will copy the files in a staged approach. This is really just a problem in our VLE environment as you are coping the files from one Git project to another Git project.*

    ```bash
    # Copy the required files.
    cp -r ~/project/gelldap/Readme.md ~/project/operator-driven/git-projects/gelldap2/
    cp -r ~/project/gelldap/bases/ ~/project/operator-driven/git-projects/gelldap2/
    cp -r ~/project/gelldap/no_TLS/ ~/project/operator-driven/git-projects/gelldap2/
    cp -r ~/project/gelldap/yes_TLS/ ~/project/operator-driven/git-projects/gelldap2/

    cd ~/project/operator-driven/git-projects/gelldap2
    ```

    Your `/git-projects/gelldap2` folder should now look like the following.

    ```log
    drwxrwxr-x 6 cloud-user cloud-user    94 Mar 11 16:37 .
    drwxrwxr-x 5 cloud-user cloud-user    50 Mar 11 16:36 ..
    drwxrwxr-x 4 cloud-user cloud-user    62 Mar 11 16:37 bases
    drwxrwxr-x 8 cloud-user cloud-user   198 Mar 11 16:37 .git
    drwxrwxr-x 2 cloud-user cloud-user   142 Mar 11 16:37 no_TLS
    -rw-rw-r-- 1 cloud-user cloud-user 12048 Mar 11 16:37 Readme.md
    drwxrwxr-x 2 cloud-user cloud-user   166 Mar 11 16:37 yes_TLS
    ```

1. Build the GELLDAP manifest (gelldap-build.yaml)

    ```bash
    cd ~/project/operator-driven/git-projects/gelldap2/no_TLS

    kustomize build -o ~/project/operator-driven/git-projects/gelldap2/gelldap-build.yaml
    ```

1. Now you need to push the files to the GELLDAP2 project. Enter the cloud-user **GitLab** credentials when prompted.

    ```bash
    cd ~/project/operator-driven/git-projects/gelldap2
    git add .
    git commit -m "Initial commit to backup the GELLDAP files"

    # Get host name and set URL
    HOST_SUFFIX=$(hostname -f)
    GELLDAP2_URL=http://gitlab.devops.${HOST_SUFFIX}/cloud-user/gelldap2.git

    # PUSH the files
    git push $GELLDAP2_URL

    # GitLab credentials
    # Username: cloud-user
    # Password: Orion1234
    ```

    Your GELLDAP2 project should now look similar to this.

    ![geldap2](/06_Deployment_Steps/img/GELLDAP2_project.png)

The final steps are to deploy the GELLDAP to the Discovery namespace.

5. First we need to create the Discovery namespace.

    ```bash
    kubectl create namespace discovery
    ```

1. Deploy GELLDAP into the Discovery namespace using your Git project. For this you will use the files stored in GitLab.

   This provides an example of using files that have been placed under source control. For this rather than using a file system reference on the `kustomize build` command you will use the Git project URL.

    ```bash
    cd ~/project/operator-driven/git-projects/gelldap2/
    # Set the namespace and deploy
    NS=discovery
    HOST_SUFFIX=$(hostname -f)
    GITLAB_URL=http://gitlab.devops.${HOST_SUFFIX}
    kubectl apply -f ${GITLAB_URL}/cloud-user/gelldap2/-/raw/master/gelldap-build.yaml -n ${NS}
    ```

1. Wait a few seconds and confirm that the service listens on port 389.

   ```bash
   # first, get the service IP:
   kubectl -n discovery get svc -l app.kubernetes.io/part-of=gelldap,app=gelldap-service -o=custom-columns='IP:spec.clusterIP' --no-headers
   # store it in a variable:
   IP_GELLDAP=$(kubectl -n discovery get svc -l app.kubernetes.io/part-of=gelldap,app=gelldap-service -o=custom-columns='IP:spec.clusterIP' --no-headers)
   # now curl it:
   curl -v ${IP_GELLDAP}:389
   ```

That concludes the prep work to stand up a GELLDAP instance for use by the Viya Discovery environment.

---

## Deploying the SAS Viya Deployment Operator

The first step is to set-up and deploy the operator in the Kubernetes cluster. Use the following instructions to do this.

### Create the working directory

You need the create a directory to hold the files to configure the operator.

1. Issue the following command to create the working directory.

    ```bash
    DEPOP_VER=stable-2020.1.5
    mkdir -p ~/project/operator-setup/${DEPOP_VER}
    cd ~/project/operator-setup/${DEPOP_VER}
    ```

### Copy the Assets and Extract

1. Get the .tgz name for the 2020.1.5 order.

    ```bash
    # Remove any existing file
    rm ~/project/operator-setup/simple_order.txt
    #
    CADENCE_NAME='stable'
    CADENCE_VERSION='2020.1.5'
    ORDER='9CFHCQ'

    ORDER_FILE=$(ls ~/orders/ \
        | grep ${ORDER} \
        | grep ${CADENCE_NAME} \
        | grep ${CADENCE_VERSION} \
        | sort \
        | tail -n 1 \
        )
    echo ${ORDER_FILE} | tee ~/project/operator-setup/simple_order.txt
    ```

1. Copy the Deployment Assets.

    ```bash
    cp ~/orders/$(cat ~/project/operator-setup/simple_order.txt) ~/project/operator-setup/${DEPOP_VER}/
    cd ~/project/operator-setup/${DEPOP_VER}
    ls -al
    ```

1. Extract the Assets.

    ```bash
    cd ~/project/operator-setup/${DEPOP_VER}
    tar xf $(cat ~/project/operator-setup/simple_order.txt)
    ```

1. Now you need the order certificates (\*.zip) and the license (\*.jwt) files. We can download these from our GELWEB server. Please copy all the lines below in one step.

    ```bash
    cd ~/project/operator-setup/${DEPOP_VER}
    GELWEB_ZIP_FOL=https://gelweb.race.sas.com/scripts/viya4orders/

    for order in $(curl -k -s  ${GELWEB_ZIP_FOL} | grep  -E -o 'href=".*\.jwt"|href=".*\.zip"' \
        | sed 's|href=||g' | sed 's|"||g' \
        | grep -i "${ORDER}" \
        | sort -u \
        ) ; do
        echo "found order called $order"
        #curl -k -o ~/project/operator-setup/${order} ${GELWEB_ZIP_FOL}/${order}
        curl -k -o ~/project/operator-setup/${DEPOP_VER}/${order} ${GELWEB_ZIP_FOL}/${order}
    done
    ```

    While you don't need the license (\*.jwt) file to deploy the operator we will download it now so that you have it ready for when you deploy a SAS Viya environment.

1. Copy the operator files to the top level of the `/operator-setup` directory and make them writable:

    ```bash
    cd ~/project/operator-setup/${DEPOP_VER}
    cp -r sas-bases/examples/deployment-operator/deploy/* .
    # Set the permissions on the file
    chmod +w site-config/transformer.yaml

    ls -al
    ```

The directory should now look similar to the following.

```log
./stable-202x.y.z/
    └── kustomization.yaml
    ├── operator-base/
    ├── sas-bases/
    ├── SASViyaV4_9CFHCQ_certs.zip
    ├── SASViyaV4_9CFHCQ_license.jwt
    ├── SASViyaV4_9CFHCQ_stable_2020.1.5_20210504.1620160646709_deploymentAssets_2021-05-05T060327.tgz
    ├── simple_order.txt
    └── site-config/
           └── cluster-wide-transformer.yaml
           └── transformer.yaml
```

The kustomization.yaml file in the `/operator-setup` directory is referred to as the '**operator kustomization.yaml**' file throughout the documentation.

---

### Deploy the SAS Viya Deployment Operator

Use the following steps to configure the operator for your environment.

#### Step 1. Edit the transformer.yaml

In the `transformer.yaml` file (_./operator-setup/site-config/transformer.yaml_) we need to set the namespace and the name for the operator ClusterRoleBinding that wil be used.

* Set namespace to: '**sasoperator**' and the name of the ClusterRole binding to '**sasopcrb**'.

  Issue the following commands to edit the file.

    ```bash
    cd ~/project/operator-setup/${DEPOP_VER}
    # Take a backup of the original file
    cp ./site-config/transformer.yaml ./site-config/transformer-bak.yaml

    # Update the default value for ClusterRole binding
    sed -i 's/{{\ NAME\-OF\-CLUSTERROLEBINDING\ }}/sasopcrb/' ./site-config/transformer.yaml
    # Update the default value for the namespace
    sed -i 's/{{\ NAME\-OF\-NAMESPACE\ }}/sasoperator/' ./site-config/transformer.yaml

    # Look at the difference to confirm the update
    icdiff site-config/transformer-bak.yaml site-config/transformer.yaml
    ```

>***Notes***
>
>*The SAS Viya Deployment Operator can be configured to respond to SASDeployment resources in its own namespace **only** (namespace scope) or in all SASDeployment resources in **all** namespaces (cluster-wide scope).*
>
>*If the operator is being used in 'namespace scope' the name of the namespace is the namespace where you will deploy SAS Viya. For example, lab or dev.*
>
>*If the operator is being used in cluster-wide scope then you need to update the kustomization.yaml file, see the next step.*

#### Step 2. Edit kustomization.yaml for cluster-wide scope

In this hands-on we will run the operator in cluster-wide scope ( but you could also run it only at the namespace level).

If the operator is being deployed in cluster-wide scope, the reference to `site-config/cluster-wide-transformer.yaml` in the operator kustomization.yaml should be uncommented.

1. Use the following command to uncomment the cluster-wide-transformer.yaml reference in the file kustomization.yaml.

    ```bash
    cd ~/project/operator-setup/${DEPOP_VER}
    sed -i 's/#- site-config/- site-config/' ./kustomization.yaml
    ```

#### Step 3. Build and Apply the manifests

The next step is to build and deploy the operator.

* Issue the following commands.

  ```bash
  # Create the namespace that will be used
  kubectl create ns sasoperator
  #
  cd ~/project/operator-setup/${DEPOP_VER}
  # Build the site.yaml for the deployment operator
  kustomize build -o operator-site.yaml
  # Apply the operator-site.yaml
  kubectl -n sasoperator apply -f operator-site.yaml
  ```

You should see the following output.

```log
$ kubectl -n sasoperator apply  -f operator-site.yaml
customresourcedefinition.apiextensions.k8s.io/sasdeployments.orchestration.sas.com configured
serviceaccount/sas-deployment-operator created
role.rbac.authorization.k8s.io/sas-deployment-operator created
clusterrole.rbac.authorization.k8s.io/sas-deployment-operator configured
rolebinding.rbac.authorization.k8s.io/sas-deployment-operator created
clusterrolebinding.rbac.authorization.k8s.io/sasoperator unchanged
secret/sas-image-pull-secrets-hbk84mfhhk created
secret/sas-license-c26m8mh9b8 created
secret/sas-lifecycle-image-gtdccb7c2b created
secret/sas-repositorywarehouse-certificates-fhf945mb44 created
deployment.apps/sas-deployment-operator created
```

### Checking the deployment (optional)

To check what was created we can do the following:

1. List the pods running in the namespace

   ```bash
   kubectl get pods -n sasoperator
   ```

   You should see that the is one pod running. The output should look something like this.

   ```log
   NAME                                       READY   STATUS    RESTARTS   AGE
   sas-deployment-operator-79f5d86fc6-lzkfj   1/1     Running   0          25s
   ```

1. Now that the operator is running you can review the sas-deployment-operator pod.

   ```bash
   kubectl describe pod sas-deployment-operator -n sasoperator
   ```

1. Check that the ClusterRoleBinding has been created. If you have overridden the default name you should see this change.

   ```bash
   kubectl get ClusterRoleBinding | grep sas-deployment-operator
   ```

1. Look at the details for the ClusterRoleBinding.

   ```bash
   kubectl describe ClusterRole/sas-deployment-operator
   ```

   You should see output similar to below.

   ```log
   Name:         sas-deployment-operator
   Labels:       app.kubernetes.io/name=sas-deployment-operator
                 sas.com/admin=cluster-wide
                 sas.com/deployment=sas-viya
   Annotations:  sas.com/component-name: sas-deployment-operator
                 sas.com/component-version: 1.45.1-20210429.1619740634080
                 sas.com/version: 1.45.1
   PolicyRule:
     Resources                                        Non-Resource URLs  Resource Names  Verbs
     ---------                                        -----------------  --------------  -----
     clusterrolebindings.rbac.authorization.k8s.io    []                 []              [bind create delete escalate get list patch update watch]
     clusterroles.rbac.authorization.k8s.io           []                 []              [bind create delete escalate get list patch update watch]
     cronjobs.batch                                   []                 []              [create get list patch update watch delete]
     jobs.batch                                       []                 []              [create get list patch update watch delete]
     rolebindings.rbac.authorization.k8s.io           []                 []              [create get list watch update patch delete bind escalate]
     roles.rbac.authorization.k8s.io                  []                 []              [create get list watch update patch delete bind escalate]
     services                                         []                 []              [get list watch create]
     sasdeployments.orchestration.sas.com             []                 []              [get list watch update]
     configmaps                                       []                 []              [list delete]
     secrets                                          []                 []              [list get delete watch create update]
     serviceaccounts                                  []                 []              [list get delete watch create update]
     sasdeployments.orchestration.sas.com/finalizers  []                 []              [update]
   ```

## Next Steps

Now that you have the environment set-up and the Deployment Operator running in cluster-wide scope, the next exercise will walk you through a deployment using a Git repository.

Click [here](/06_Deployment_Steps/06_093_Using_the_DO_with_a_Git_Repository.md) to move onto the next exercise: [06_093_Using_the_DO_with_a_Git_Repository](/06_Deployment_Steps/06_093_Using_the_DO_with_a_Git_Repository.md).

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
* [06 Deployment Steps / 06 091 Deployment Operator setup](/06_Deployment_Steps/06_091_Deployment_Operator_setup.md)**<-- you are here**
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
