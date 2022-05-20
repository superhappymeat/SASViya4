![Global Enablement & Learning](https://gelgitlab.race.sas.com/GEL/utilities/writing-content-in-markdown/-/raw/master/img/gel_banner_logo_tech-partners.jpg)

* [Generic example](#generic-example)
  * [Create namespace](#create-namespace)
  * [Create Service Account with cluster-admin permissions in namespace](#create-service-account-with-cluster-admin-permissions-in-namespace)
  * [Get secret and certificate](#get-secret-and-certificate)
  * [Create kubeconfig file](#create-kubeconfig-file)
  * [Test it with namespaces test1 and test2](#test-it-with-namespaces-test1-and-test2)
* [Create a viya admin service account](#create-a-viya-admin-service-account)
  * [Create the viya-admin Service Account for our namespace](#create-the-viya-admin-service-account-for-our-namespace)
  * [Create the ClusterRole for "cluster-local" scope](#create-the-clusterrole-for-cluster-local-scope)
  * [Create the ClusterRole for "namespace" scope](#create-the-clusterrole-for-namespace-scope)
  * [Bind cluster-local, namespaces and cluster-admin ClusterRoles to our viya-admin account](#bind-cluster-local-namespaces-and-cluster-admin-clusterroles-to-our-viya-admin-account)
  * [Get viya admin secret, token and certificate](#get-viya-admin-secret-token-and-certificate)
  * [Create the viya admin kubeconfig file](#create-the-viya-admin-kubeconfig-file)
* [Switch to the restricted KUBECONFIG](#switch-to-the-restricted-kubeconfig)
* [Testing with a Viya deployment](#testing-with-a-viya-deployment)
* [Additional permissions to be able to restart the Viya environment with viya admin](#additional-permissions-to-be-able-to-restart-the-viya-environment-with-viya-admin)
* [References](#references)

# Create Viya deployment Roles

## Generic example

### Create namespace

```bash
kubectl create namespace test1
kubectl create namespace test2
```

### Create Service Account with cluster-admin permissions in namespace

We create a service account with cluster-admin permissions, but limited to the namespace test1.
We use the predefined ClusterRole "cluster-admin" but with the "RoleBinding" we limit his permissions to the namespace.

```yaml
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: test1-admin
  namespace: test1

---
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
  name: test1-admin-binding
  namespace: test1
subjects:
- kind: ServiceAccount
  name: test1-admin
  namespace: test1
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
```

Run the code below to create the file content and apply it.

```bash
tee /tmp/create-namespace-admin.yaml > /dev/null << EOF
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: test1-admin
  namespace: test1

---
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
  name: test1-admin-binding
  namespace: test1
subjects:
- kind: ServiceAccount
  name: test1-admin
  namespace: test1
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
EOF
kubectl apply -f /tmp/create-namespace-admin.yaml
```

### Get secret and certificate

to get the name of the service account’s secret. run the command below

```sh
kubectl describe sa test1-admin -n test1
```

you can also get it automatically into a variable with :

```bash
SECRET=$(kubectl get sa test1-admin -n test1 -o jsonpath='{.secrets[].name}')
```

We now need to get the service account's Token and the Certificate Authority. For this, we are going to read them using kubectl. Now, as Kubernetes secrets are base64 encoded, we’ll also need to decode them.

Here’s how you get the User Token:

```sh
kubectl get secret $SECRET -n test1 -o "jsonpath={.data.token}" | base64 -d
```

And here's how we get the certificate:

```sh
kubectl get secret $SECRET -n test1 -o "jsonpath={.data['ca\.crt']}"
```

### Create kubeconfig file

We now have everything we need. The only thing remaining is creating the Kube config file, with the data we previously gathered.

First let's store the secret and certs in variables

```bash
USERTOKEN=$(kubectl get secret $SECRET -n test1 -o "jsonpath={.data.token}" | base64 -d)
CLIENTCERT=$(kubectl get secret $SECRET -n test1 -o "jsonpath={.data['ca\.crt']}")
```

We also need to get the Cluster API Endpoint.

Let's try to get it from the default kubeconfig file.

```bash
APIEP=$(grep "server:" ~/.kube/config | awk -F "//" '{print $2}' | tr -d ' ')
echo $APIEP
```

Now we generate our kubeconfig.

```bash
tee /tmp/test1-admin-kubeconfig > /dev/null << EOF
apiVersion: v1
kind: Config
preferences: {}

# Define the cluster
clusters:
- cluster:
    certificate-authority-data: ${CLIENTCERT}
    # You'll need the API endpoint of your Cluster here:
    server: https://${APIEP}
  name: ${STUDENT}viya4aks-aks

# Define the user
users:
- name: test1-admin
  user:
    as-user-extra: {}
    client-key-data: ${CLIENTCERT}
    token: ${USERTOKEN}

# Define the context: linking a user to a cluster
contexts:
- context:
    cluster: ${STUDENT}viya4aks-aks
    namespace: test1
    user: test1-admin
  name: test1

# Define current context
current-context: test1
EOF
```

Now unset the secret and certificate variables.

```bash
unset USERTOKEN
unset CLIENTCERT
unset SECRET
```

### Test it with namespaces test1 and test2

* Set KUBECONFIG and Basic test (ensure the proper Kube Config file is in use)

    ```bash
    #export KUBECONFIG=~/.kube/config
    export KUBECONFIG=/tmp/test1-admin-kubeconfig
    kubectl config view
    ```

* Create a dummy pod

    ```bash
    tee /tmp/kuardpod.yaml > /dev/null << EOF
    ---
    apiVersion: v1
    kind: Pod
    metadata:
      name: kuard
    spec:
      containers:
        - image: gcr.io/kuar-demo/kuard-amd64:blue
          name: kuard
          ports:
            - containerPort: 8080
              name: http
              protocol: TCP
    EOF
    ```

* create the pod in the test1 namespace (allowed)

```bash
kubectl --kubeconfig /tmp/test1-admin-kubeconfig -n test1 apply -f /tmp/kuardpod.yaml
```

* create the pod in the test2 namespace (forbidden)

```bash
kubectl --kubeconfig /tmp/test1-admin-kubeconfig -n test2 apply -f /tmp/kuardpod.yaml
```

As you can see, you can create a resource in the "test1" namespace but not in the "test2" namespace.

* clean up

```bash
export KUBECONFIG=~/.kube/config
kubectl delete ns test1 test2
```

## Create a viya admin service account

_Note : if you want to test the instructions with a real Viya deployment in your environment using 2 level of permissions, start from [there](#testing-with-a-viya-deployment)_

In the viya deployment, the resources are broken down in 3 types : cluster-wide, cluster-local and namespace.

![restricted_roles](img/restricted_roles.png)

We want to create a specific Service Account that can be used to deploy the "namespace" level Viya component.

In our scenario, the Kubernetes administrator would deploy the cluster-wide scope resources using its own privileged access, then he will create a restricted service account, generate the associated Kubeconfig file and provide it to the SAS Consultant to allow him to deploy the remaining Viya components ("cluster-local" and "namespace" scope) without the risk to break or modify anything else in the other namespaces.

Unfortunately, we can not ONLY rely to the technique described in the general example above with the default "cluster-admin" ClusterRole associated to our namespace with a RoleBinding.

It will not provide enough permissions for things like the operators that need specific privileges outside of the namespace.

We need to add some additional ClusterRoles associated with ClusterRoleBinding to our service account to allow specific operation at the Cluster level.

To simplify the same viya-admin service account will be use for both "cluster-local" and "namespace" scopes, but we could have had 2 different service account corresponding to the 2 scopes.

### Create the viya-admin Service Account for our namespace

Set the namespace

```bash
export NAMESPACE="lab"
```

Run the code below to create the viya-admin service account in our namespace.

```bash
tee /tmp/create-viya-admin-sa-${NAMESPACE}.yaml > /dev/null << EOF
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: viya-admin-${NAMESPACE}
  namespace: ${NAMESPACE}
EOF
```

Apply the manifest:

```bash
kubectl apply -f /tmp/create-viya-admin-sa-${NAMESPACE}.yaml
```

### Create the ClusterRole for "cluster-local" scope

Allow "clusterbindings" resources creation and give read access privileges on the nodes.

```bash
tee /tmp/create-clusterlocalscope-clusterrole.yaml > /dev/null << EOF
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: sas-clusterrole-cluster-local
rules:
- apiGroups: ["rbac.authorization.k8s.io"]
  resources: ["clusterrolebindings"]
  verbs: ["get", "list", "watch", "create", "patch", "update", "delete"]
- apiGroups: [""]
  resources: ["nodes"]
  verbs: ["get", "list", "watch"]

EOF
```

Apply the manifests

```bash
kubectl apply -f /tmp/create-clusterlocalscope-clusterrole.yaml
```

### Create the ClusterRole for "namespace" scope

The ClusterRole to allow to see other namespaces and create the PVs.

```bash
tee /tmp/create-namespacescope-clusterrole.yaml > /dev/null << EOF
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: sas-clusterrole-namespace
rules:
- apiGroups: [""]
  resources: ["namespaces"]
  verbs: ["get", "watch", "list"]
- apiGroups: [""]
  resources: ["persistentvolumes"]
  verbs: ["get", "watch", "list"]
EOF
```

Apply the manifests

```bash
kubectl apply -f /tmp/create-namespacescope-clusterrole.yaml
```

### Bind cluster-local, namespaces and cluster-admin ClusterRoles to our viya-admin account

We associate the ClusterRoles to our viya-admin service account ("cluster-admin" is binded at the namespace level and our custom ClusterRole are binded at the Cluster level).

```bash
tee /tmp/create-binding-for-viya-admin-${NAMESPACE}.yaml > /dev/null << EOF
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: sas-rolebinding-namespace
  namespace: ${NAMESPACE}
subjects:
- kind: ServiceAccount
  name: viya-admin-${NAMESPACE}
  namespace: ${NAMESPACE}
roleRef:
  kind: ClusterRole
  name: cluster-admin
  apiGroup: rbac.authorization.k8s.io

---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: sas-rolebinding-cluster-local
  namespace: ${NAMESPACE}
subjects:
- kind: ServiceAccount
  name: viya-admin-${NAMESPACE}
  namespace: ${NAMESPACE}
roleRef:
  kind: ClusterRole
  name: cluster-admin
  apiGroup: rbac.authorization.k8s.io

---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: sas-clusterrolebinding-namespace
subjects:
- kind: ServiceAccount
  name: viya-admin-${NAMESPACE}
  namespace: ${NAMESPACE}
roleRef:
  kind: ClusterRole
  name: sas-clusterrole-namespace
  apiGroup: rbac.authorization.k8s.io

---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: sas-clusterrolebinding-cluster-local
subjects:
- kind: ServiceAccount
  name: viya-admin-${NAMESPACE}
  namespace: ${NAMESPACE}
roleRef:
  kind: ClusterRole
  name: sas-clusterrole-cluster-local
  apiGroup: rbac.authorization.k8s.io
EOF
```

Apply the manifest:

```bash
kubectl apply -f /tmp/create-binding-for-viya-admin-${NAMESPACE}.yaml
```

### Get viya admin secret, token and certificate

Get the name of the service account's secret.

```bash
SECRET=$(kubectl get sa viya-admin-${NAMESPACE} -n ${NAMESPACE} -o jsonpath='{.secrets[].name}')
```

Let's store the secret and certs for our viya-admin SA in variables

```bash
USERTOKEN=$(kubectl get secret $SECRET -n ${NAMESPACE} -o "jsonpath={.data.token}" | base64 -d)
CLIENTCERT=$(kubectl get secret $SECRET -n ${NAMESPACE} -o "jsonpath={.data['ca\.crt']}")
```

### Create the viya admin kubeconfig file

Let's create a folder to place our future Kube config.

```bash
mkdir -p ~/viya-admin
```

Set the STUDENT environment varaible with your own name.

```bash
export STUDENT="your_name"
```

We have everything we need in terms of token and certficates.
But to propulate the Kube config file we also need to get the Cluster API Endpoint.

Let's try to get it from the default kubeconfig file.

```bash
APIEP=$(grep "server:" ~/.kube/config | awk -F "//" '{print $2}' | tr -d ' ')
echo $APIEP
```

Now we generate our kubeconfig.

```bash
tee ~/viya-admin/viya-admin-${STUDENT}-kubeconfig > /dev/null << EOF
apiVersion: v1
kind: Config
preferences: {}

# Define the cluster
clusters:
- cluster:
    certificate-authority-data: ${CLIENTCERT}
    # You'll need the API endpoint of your Cluster here:
    server: https://${APIEP}
  name: ${STUDENT}viya4aks-aks

# Define the user
users:
- name: viya-admin-${NAMESPACE}
  user:
    as-user-extra: {}
    client-key-data: ${CLIENTCERT}
    token: ${USERTOKEN}

# Define the context: linking a user to a cluster
contexts:
- context:
    cluster: ${STUDENT}viya4aks-aks
    namespace: ${NAMESPACE}
    user: viya-admin-${NAMESPACE}
  name: ${NAMESPACE}

# Define current context
current-context: ${NAMESPACE}
EOF
```

Now unset the secret and certificate variables.

```bash
unset USERTOKEN
unset CLIENTCERT
unset SECRET
```

Now you should be able to use this KUBECONFIG file to deploy the "cluster-local" and "namespace" scope Viya resources in the Kuberenetes cluster with restricted permissions (instead of alawys using the K8s super-administrator KUBECONFIG file).

## Switch to the restricted KUBECONFIG

There are two main ways to use a specific KUBECONFIG file when interacting with the cluster.
Ether using the KUBECONFIG environment variable

```bash
export KUBECONFIG=~/viya-admin/viya-admin-${STUDENT}-kubeconfig
```

or using the --kubeconfig option in the kubectl commands

```bash
kubectl --kubeconfig ~/viya-admin/viya-admin-${STUDENT}-kubeconfig get pods
```

Will return the list of pods in the ${NAMESPACE}.

But the command below :

```bash
kubectl create ns test3
```

Should return a permission error :

```log
Error from server (Forbidden): namespaces is forbidden: User "system:serviceaccount:test:viya-admin-test" cannot create resource "namespaces" in API group "" at the cluster scope
```

## Testing with a Viya deployment

* If you already have a running deployment in RACE or AKS, you can remove it and redeploy it in 3 commands with different KUBECONFIG.
* Uncomment lines below. Adjust them to your environment or namespace as required.

    ```bash
    # Delete your existing deployment namespace
    #kubectl delete ns ${NAMESPACE}
    #kubectl create ns ${NAMESPACE}
    export KUBECONFIG=~/.kube/config
    kubectl delete lab
    kubectl delete dev
    kubectl delete po
    ```

* Set the namespace where we will work

    ```bash
    export NAMESPACE="lab"
    kubectl create ns ${NAMESPACE}
    ```

* Perform all the steps from [there](#create-the-viya-admin-service-account-for-namespace)

* Uncomment lines below. Adjust them to your environment or namespace as required.

    ```bash
    # Move to the folder that contains your site.yaml
    #cd ~/clouddrive/project/deploy/${NAMESPACE}
    #cd ~/project/deploy/${NAMESPACE}
    cd ~/project/deploy/${NAMESPACE}
    ```

* Apply the "cluster wide" configuration in site.yaml (CRDs, Roles, Service Accounts) as the Kubernetes Administrator with the administration KUBECONFIG.

    ```bash
    export KUBECONFIG=~/.kube/config
    kubectl apply --selector="sas.com/admin=cluster-wide" -f site.yaml -n ${NAMESPACE}
    ```

* Wait for Custom Resource Deployment to be deployed

    ```bash
    kubectl wait --for condition=established --timeout=60s -l "sas.com/admin=cluster-wide" crd -n ${NAMESPACE}
    ```

* Now, switch to the restricted KUBECONFIG and apply the "cluster local" configuration in site.yaml.

    ```bash
    export KUBECONFIG=~/viya-admin/viya-admin-${STUDENT}-kubeconfig
    kubectl apply --selector="sas.com/admin=cluster-local" -f site.yaml --prune -n ${NAMESPACE}
    ```

* Still with the restricted KUBECONFIG, apply the configuration in manifest.yaml that matches label "sas.com/admin=namespace".

    ```bash
    #export KUBECONFIG=~/viya-admin/viya-admin-${STUDENT}-kubeconfig
    kubectl  apply --selector="sas.com/admin=namespace" -f site.yaml --prune -n ${NAMESPACE}
    ```

    There are many ways to configure RBAC to allow the deployment of the "cluster-local" and "namespace" scopes Viya resources with a restricted service account (for example by creating role listing explicitly all allowed actions or with a different repartition of the 3 levels between different service accounts), but in this example we've shown how the tasks can be broken down between the super administrator (K8s admin) and someone with a more restricted set of privileges.

## Additional permissions to be able to restart the Viya environment with viya admin

```sh
tee /tmp/create-clusterlocalscope-clusterrole.yaml > /dev/null << EOF
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: sas-clusterrole-cluster-local
rules:
- apiGroups: ["rbac.authorization.k8s.io"]
  resources: ["clusterrolebindings"]
  verbs: ["get", "list", "watch", "create", "patch", "update", "delete"]
- apiGroups: [""]
  resources: ["nodes"]
  verbs: ["get", "list", "watch"]

#additional rules to stop all
- apiGroups: ["rbac.authorization.k8s.io"]
  resources: ["clusterroles"]
  verbs: ["get", "list", "watch"]
- apiGroups: ["apiextensions.k8s.io"]
  resources: ["customresourcedefinitions"]
  verbs: ["get", "list", "watch"]
- apiGroups: ["crunchydata.com"]
  resources: ["*"]
  verbs: ["create", "delete", "deletecollection", "patch", "update", "get", "list", "watch"]
- apiGroups: ["casdeployments.viya.sas.com"]
  resources: ["*"]
  verbs: ["create", "delete", "deletecollection", "patch", "update", "get", "list", "watch"]
- apiGroups: ["iot.sas.com"]
  resources: ["*"]
  verbs: ["get", "delete", "list", "deletecollection"]

EOF
kubectl apply -f /tmp/create-clusterlocalscope-clusterrole.yaml -n ${NAMESPACE}
```

## References

* [K8s RBAC](https://kubernetes.io/docs/reference/access-authn-authz/rbac/)
* [KUBERNETES AND RBAC: RESTRICT USER ACCESS TO ONE NAMESPACE](https://jeremievallee.com/2018/05/28/kubernetes-rbac-namespace-user.html)

Credits : Thanks to Jan Siestra _(Jan.Stienstra@sas.com)_ for sharing its tests and findings in this space.

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
* [06 Deployment Steps / 06 101 Create Viya Deployment Roles](/06_Deployment_Steps/06_101_Create_Viya_Deployment_Roles.md)**<-- you are here**
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
