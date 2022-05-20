![Global Enablement & Learning](https://gelgitlab.race.sas.com/GEL/utilities/writing-content-in-markdown/-/raw/master/img/gel_banner_logo_tech-partners.jpg)

# Enabling HA

**DRAFT**

* [Working location](#working-location)
* [Start from gelenv](#start-from-gelenv)
* [Add the ha line in the kustomization.yaml](#add-the-ha-line-in-the-kustomizationyaml)
* [Experimentation](#experimentation)
  * [set the max HPA to 10](#set-the-max-hpa-to-10)

## Working location

1. for this exercise, we will work in this folder:

    ```bash
    mkdir -p ~/project/deploy/gelenv-ha

    ```

## Start from gelenv

1. execute those steps to quickly generate a "default" deployment without HA

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
            GELENV_ROOT=/home/cloud-user/project/deploy/gelenv-ha    \
            GELENV_INGRESS_PREFIX=gelenv    \
            GELENV_HA=false'

    ```

## Add the ha line in the kustomization.yaml

1. add the line

    ```bash
    cp ~/project/deploy/gelenv-ha/kustomization.yaml ~/project/deploy/gelenv-ha/kustomization.yaml.orig
    printf "
    - command: update
      path: transformers[+]
      value:
        sas-bases/overlays/scaling/ha/enable-ha-transformer.yaml       # enable HA
    " | yq -I 4 w -i -s - ~/project/deploy/gelenv-ha/kustomization.yaml

    icdiff ~/project/deploy/gelenv-ha/kustomization.yaml.orig ~/project/deploy/gelenv-ha/kustomization.yaml

    ```

1. and then, rebuild the manifest

    ```bash
    cp site.yaml site.yaml.orig
    time kustomize build -o site.yaml

    icdiff site.yaml.orig site.yaml
    ```

1. Now, apply the newly update manifest

    ```bash
    kubectl apply -n gelenv -f site.yaml

    ```

1. check how long it takes for the new pods to come fully online

1. confirm that in the meantime, the environment is still accessible

## Experimentation

### set the max HPA to 10

1. fair warning; this is not recommended. it gives a weird result.

    ```bash

    mkdir -p ~/project/deploy/gelenv-ha/site-config/ha/

    tee  ~/project/deploy/gelenv-ha/site-config/ha/ha10max.yaml > /dev/null << "EOF"
    ---
    apiVersion: builtin
    kind: PatchTransformer
    metadata:
      name: enable-ha-hpa-replicas
    patch: |-
      - op: replace
        path: /spec/maxReplicas
        value: 10
      - op: replace
        path: /spec/minReplicas
        value: 2
    target:
      kind: HorizontalPodAutoscaler
      version: v2beta2
      apps: autoscaling
    ---
    apiVersion: builtin
    kind: PatchTransformer
    metadata:
      name: enable-ha-centralized-hpa-replicas
    patch: |-
      - op: replace
        path: /spec/maxReplicas
        value: 10
      - op: replace
        path: /spec/minReplicas
        value: 2
    target:
      kind: HorizontalPodAutoscaler
      version: v2beta2
      apps: autoscaling
      annotationSelector: sas.com/ha-class=centralized
    ---
    apiVersion: builtin
    kind: PatchTransformer
    metadata:
      name: enable-ha-centralized-pdb-min-available
    patch: |-
      - op: replace
        path: /spec/minAvailable
        value: 1
    target:
      kind: PodDisruptionBudget
      version: v1beta1
      apps: policy
      annotationSelector: sas.com/ha-class=centralized

    EOF

    ```

1. then update the kustomization.yaml.tls.ha

    ```bash
    ansible localhost \
    -m replace \
    -a  "dest=~/project/deploy/gelenv-ha/kustomization.yaml \
        regexp='sas-bases\/overlays\/scaling\/ha\/enable-ha-transformer\.yaml' \
        replace='site-config/ha/ha10max.yaml' \
        backup=yes " \
        --diff
    ```

1. build and apply

    ```bash
    time kustomize build -o site.yaml
    kubectl apply -f site.yaml
    ```
