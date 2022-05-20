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
* [Table of Contents for the Deployment Operator exercises](#table-of-contents-for-the-deployment-operator-exercises)
* [Navigation](#navigation)

## Introduction

Using the Orchestration Tool... the easy path! :-)

Now that you have had the experience of editing YAML files by hand, we will now look at using the Orchestration Tool for generate the custom resource.

For this set of exercises you will use the tool to generate an inline CR file, then you will use the tool to generate a CR that is using the Git Repository.

To do this you need to first pull down the Orchestration Tool.

***This exercise assumes that you have completed the initial setup steps and the Discovery environment (using Git) exercises. See [here](./11_310_Using_the_DO_with_a_Git_Repository.md)***.

## Environment setup - getting the Orchestration Tool

The SASDeployment custom resource can be created and maintained using the orchestration tool. The instructions to deploy the orchestration tool are in the “Prerequisites” section of the README file at $deploy/sas-bases/examples/kubernetes-tools/README.md (for Markdown format) or $deploy/sas-bases/docs/using_kubernetes_tools_from_the_sas-orchestration_image.htm (for HTML format).

### Pull the orchestration tool image from SAS

Use the following steps.

1. Log in to the SAS Registry (cr.sas.com), and retrieve the `sas-orchestration` image.

    ```bash
    # Set environment variable
    DEPOP_VER=stable-2020.1.5

    cd ~/project/operator-setup/${DEPOP_VER}

    # Get the order number
    ORDERNUM=$(echo $(ls ~/project/operator-setup/${DEPOP_VER}/*tgz) | sed 's/^.*SASViyaV4_/SASViyaV4_/' | cut -d "_" -f 2)

    # Get the sas-orchestration image version from the README
    IMAGE_VERSION=$(cat ~/project/operator-setup/${DEPOP_VER}/sas-bases/examples/kubernetes-tools/README.md | grep "docker tag cr.sas.com/viya-4-x64_oci_linux_2-docker/sas-orchestration:" | sed 's/^.*sas-orchestration:/sas-orchestration:/' | cut -d " " -f 1 | cut -d ":"  -f 2)

    # Login to Docker registry and pull the sas-orchestration image
    cat sas-bases/examples/kubernetes-tools/password.txt | docker login cr.sas.com --username ${ORDERNUM} --password-stdin
    docker pull cr.sas.com/viya-4-x64_oci_linux_2-docker/sas-orchestration:${IMAGE_VERSION}
    ```

1. Logout of cr.sas.com

    ```bash
    docker logout cr.sas.com
    ```

1. Replace the image tag

    Replace 'cr.sas.com/viya-4-x64_oci_linux_2-docker/sas-orchestration:x.xx.x-yyymmdd.xxxxxxxxxxxxx' with a local tag for ease of use. We will use 'sas-orch'.

    ```bash
    docker tag cr.sas.com/viya-4-x64_oci_linux_2-docker/sas-orchestration:${IMAGE_VERSION} sas-orch
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
    STUDENT=$(cat ~/student.txt)
    INGRESS_FQDN=$STUDENT.gelsandbox.aks.unx.sas.com
    PROJECT_URL=http://gitlab.${INGRESS_FQDN}/root/discovery.git

    # Commit the updates
    git add .
    git commit -m "Commit the Viya certs zip file"

    # PUSH the files
    git push $PROJECT_URL
    ```

1. Create the Custom Resource using a Git project and write the CR to the Git project folder.

    ```bash
    cd ~/project/operator-driven/inline-projects/

    GITLAB_URL=http://gitlab.${INGRESS_FQDN}

    docker run --rm \
    -v ${PWD}:/cr-working \
    -w /cr-working \
    --user $(id -u):$(id -g) \
    sas-orch \
    create sas-deployment-cr \
    --deployment-data ${GITLAB_URL}/root/discovery/-/raw/master/secrets/SASViyaV4_certs.zip \
    --license  ${GITLAB_URL}/root/discovery/-/raw/master/secrets/license/SASViyaV4_license.jwt \
    --user-content git::${GITLAB_URL}/root/discovery.git \
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
cd ~/project/operator-driven/git-projects/gelldap2/
kubectl apply -f gelldap-build.yaml -n ${NS}


# Apply the CR to deploy a new discovery environment
cd ~/project/operator-driven/git-projects/discovery
kubectl apply -f discovery2-sasdeployment.yaml -n discovery
```

As you can see, using the Orchestration Tool is definitely easier than manually creating and editing the custom resource YAML file.

Remember you still need to create the Viya kustomizations to configure the SAS Viya environment. In this case we reused the Discovery configuration that you created earlier.

**This concludes the deployment operator exercises**.

## Table of Contents for the Deployment Operator exercises

<!--Navigation for this set of labs-->
* [11 100 Creating an AKS Cluster](../11_100_Creating_an_AKS_Cluster.md)
* [11 110 Performing Prereqs in AKS](../11_110_Performing_the_prerequisites.md)
* [11 300 Deployment Operator environment set-up](./11_300_Deployment_Operator_environment_set-up.md)
* [11 310 Using the Deployment Operator with a Git Repository](./11_310_Using_the_DO_with_a_Git_Repository.md)
* [11 320 Using the Deployment Operator with an inline configuration](./11_320_Using_an_inline_configuration.md)
* [11 330 Using the Orchestration Tool to create the SASDeployment Custom Resource](./11_330_Using_the_Orchestration_Tool.md) **<-- You are here**

## Navigation

