#!/bin/bash

timestamp() {
  date +"%T"
}
datestamp() {
  date +"%D"
}

function logit () {
    sudo touch ${RACEUTILS_PATH}/logs/${HOSTNAME}.bootstrap.log
    sudo chmod 777 ${RACEUTILS_PATH}/logs/${HOSTNAME}.bootstrap.log
    printf "$(datestamp) $(timestamp): $1 \n"  | tee -a ${RACEUTILS_PATH}/logs/${HOSTNAME}.bootstrap.log
}

## Read in the id file. only really needed if running these scripts in standalone mode.
source <( cat /opt/raceutils/.bootstrap.txt  )
source <( cat /opt/raceutils/.id.txt  )
reboot_count=$(cat /opt/raceutils/.reboot.txt)


case "$1" in
    'enable')


    ;;
    'dev')

    ;;

    'start')

        if  [ "$race_alias" == "sasnode01" ] && [ "$reboot_count" -le "1" ] ;     then

        if helm list --all-namespaces | grep -q 'my-nginx'
        then
            sudo -u cloud-user bash -c "   helm uninstall  my-nginx --namespace nginx  "
        fi
        if kubectl get ns | grep -q 'nginx\ '
        then
            kubectl delete ns nginx
        fi

        # sudo -u cloud-user bash -c "helm repo add stable https://kubernetes-charts.storage.googleapis.com/"
        # sudo -u cloud-user bash -c "helm repo update"
        # hot fix as googleapis are deprecated
        # - see : https://helm.sh/docs/faq/#i-am-getting-a-warning-about-unable-to-get-an-update-from-the-stable-chart-repository
        sudo -u cloud-user bash -c "helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx; \
                                    helm repo update"

        ## NGINX ingress on 80/443
    function deploy_nginx (){
        sudo -u cloud-user bash -c " kubectl create ns nginx   "

        sudo -u cloud-user bash -c "   helm install  my-nginx --namespace nginx  \
            --set controller.service.type=NodePort \
            --set controller.service.nodePorts.http=80 \
            --set controller.service.nodePorts.https=443 \
            --set controller.extraArgs.enable-ssl-passthrough="" \
            --set controller.autoscaling.enabled=true \
            --set controller.autoscaling.minReplicas=2 \
            --set controller.autoscaling.maxReplicas=5 \
            --set controller.resources.requests.cpu=100m \
            --set controller.resources.requests.memory=500Mi \
            --set controller.autoscaling.targetCPUUtilizationPercentage=90 \
            --set controller.autoscaling.targetMemoryUtilizationPercentage=90 \
            --set controller.admissionWebhooks.patch.image.repository=gelharbor.race.sas.com/dockerhubstaticcache/jettech/kube-webhook-certgen \
            --set controller.admissionWebhooks.patch.image.tag=v1.5.0 \
            --version 3.20.1 \
            ingress-nginx/ingress-nginx "

        kubectl wait -n nginx --for=condition=available  --all deployments --timeout=60s
        kubectl wait -n nginx --for=condition=available  --all deployments --timeout=60s
    }

        deploy_nginx
        if [ $? -ne 0 ] ; then
            logit "There was a problem with NGINX. Trying a second time "
            deploy_nginx
            if [ $? -ne 0 ] ; then
                logit "Second NGINX attempt also failed. "
                logit "In order to resolve this issue, please execute the following: "
                logit "\nsudo bash ~/PSGEL255-deploying-viya-4.0.1-on-kubernetes/scripts/loop/GEL.09.Ingress.sh start "
            fi
            logit "seems that the second time was the charm for nginx. continuing."
            #kubectl wait -n nginx --for=condition=available  --all deployments --timeout=86400s

        fi

            ## the ssl-passthrough line is important for argocd to work

        ## TRAEFIK ingress
        function deploy_traefik () {
        if helm list --all-namespaces | grep -q 'traefik'
        then
            sudo -u cloud-user bash -c "helm uninstall  my-traefik --namespace traefik"
            sudo -u cloud-user bash -c "kubectl delete clusterrolebinding permissive-binding "

        fi
        if kubectl get ns | grep -q 'traefik\ '
        then
            kubectl delete ns traefik
        fi

        sudo -u cloud-user bash -c "kubectl create ns traefik"
        sudo -u cloud-user bash -c "kubectl create \
            clusterrolebinding permissive-binding \
            --clusterrole=cluster-admin \
            --user=admin \
            --user=kubelet \
            --group=system:serviceaccounts"

        # https://medium.com/@patrickeasters/using-traefik-with-tls-on-kubernetes-cb67fb43a948
        # openssl req \
        #         -newkey rsa:2048 -nodes -keyout tls.key \
        #         -x509 -days 365 -out tls.crt
        # kubectl create secret generic traefik-cert \
        #         --from-file=tls.crt \
        #         --from-file=tls.key

        # sudo -u cloud-user bash -c "openssl req  -newkey rsa:2048 -nodes -keyout /tmp/tls_traefik.key  -x509 -days 365 -out /tmp/tls_traefik.crt -subj \"/C=US/ST=NC/L=Cary/O=SAS/OU=ContainersTraining/CN=*.$(hostname -f)\""
        # sudo -u cloud-user bash -c "kubectl create secret generic traefik-cert  --from-file=/tmp/tls_traefik.crt   --from-file=/tmp/tls_traefik.key "

                # --set serviceType=NodePort \
                # --set service.nodePorts.http=81 \
                # --set service.nodePorts.https=444 \
                # --set dashboard.enabled=true \
                # --set dashboard.domain=traefikdashboard.$(hostname -f) \
                # --set ssl.generateTLS=true \
                # --set ssl.insecureSkipVerify=true \
                # --set accessLogs.enabled=true \

tee /tmp/traefik.values.yaml > /dev/null <<EOF
deployment:
  enabled: true
  # Can be either Deployment or DaemonSet
  kind: Deployment
  # Number of pods of the deployment (only applies when kind == Deployment)
  replicas: 2
ports:
  # The name of this one can't be changed as it is used for the readiness and
  # liveness probes, but you can adjust its config to your liking
  traefik:
    port: 9000
    expose: false
    # The exposed port for this service
    exposedPort: 9000
    # The port protocol (TCP/UDP)
    protocol: TCP
  web:
    port: 8000
    # hostPort: 8000
    expose: true
    exposedPort: 81
    # The port protocol (TCP/UDP)
    protocol: TCP
    # Use nodeport if set. This is useful if you have configured Traefik in a
    # LoadBalancer
    nodePort: 81
  websecure:
    port: 8443
    # hostPort: 8443
    expose: true
    exposedPort: 444
    # The port protocol (TCP/UDP)
    protocol: TCP
service:
  enabled: true
  type: NodePort
ingressRoute:
  dashboard:
    enabled: true
EOF


        sudo -u cloud-user bash -c " helm repo add traefik https://helm.traefik.io/traefik ; \
            helm repo update ; \
            helm install  my-traefik \
                --namespace traefik \
                --values /tmp/traefik.values.yaml \
                traefik/traefik "

            # --set forwardedHeaders.enabled=true \
            # --set ssl.defaultCN=\"*.$(hostname -f)\" \

        printf "\n* [Traefik Dashboard URL (HTTP )](http://traefikdashboard.$(hostname -f)/ )\n\n" | tee -a /home/cloud-user/urls.md
        printf "\n* [Traefik Dashboard URL (HTTP**S**)](https://traefikdashboard.$(hostname -f)/ )\n\n" | tee -a /home/cloud-user/urls.md
        }

        # deploy_traefik

        #  --set ssl.defaultSANList=\"*.$(hostname -f)\" \
        #     --set ssl.defaultIPList=\"$(hostname -i)\" \
        fi

    ;;
    'stop')

    ;;
    'clean')

    ;;

    *)
        printf "Usage: GEL.00.Clone.Project.sh {enable/start|stop|clean} \n"
        exit 1
    ;;
esac

