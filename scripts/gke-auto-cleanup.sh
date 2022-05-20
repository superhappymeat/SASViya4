#WORKING :
#ActivityInLastXHours=$(gcloud logging read "resource.type=gke_cluster AND logName=projects/sas-gelsandbox/logs/cloudaudit.googleapis.com%2Factivity \
#AND protoPayload.metadata.operationType=CREATE_CLUSTER \
#AND protoPayload.resourceName:raphpoumarv4-gke
#AND timestamp > \"$XHOURSAGO\"" --limit 10 --format json

#Parameter
X=1
PROJECT=sas-gelsandbox
# Date computations
DATENOWUTC=$(date -u '+%Y-%m-%dT%H:%M:%SZ')
XHOURSAGO=$(TZ=UTC date -d "$DATENOWUTC - $X hours" +%Y-%m-%dT%H:%M:%SZ)
echo "Date Now(UTC):"$DATENOWUTC
echo "Date" $X "hours ago" : $XHOURSAGO

GKECLUSTERS=$(gcloud container clusters list | grep -v "NAME" | awk '{print $1}')
#gcloud container clusters list --filter="NAME:(v4-gke)"

# delete GKE Clusters
for gk in $GKECLUSTERS
do
    ResourceName=$gk
    STUDENT=${gk%v4-gke*}
    echo "Cluster:"${gk}
    echo "STUDENT:"${STUDENT}
    # Detect Cluster created less than X hours ago
    ActivityInLastXHours=$(gcloud logging read "resource.type=gke_cluster AND logName=projects/${PROJECT}/logs/cloudaudit.googleapis.com%2Factivity \
    AND protoPayload.metadata.operationType=CREATE_CLUSTER \
    AND protoPayload.resourceName:\"$ResourceName\" \
    AND timestamp > \"$XHOURSAGO\"")

    if [ -z "$ActivityInLastXHours" ]
    then
        #mail -s "Your AKS cluster has been running for more than $X hours,so we will delete it now" $sasid@sas.com  < /dev/null
        mail -s "WARNING DELETE : for GKE Cluster: $gk at ${UTIME}(UTC) - no activity detected in the last ${X} hours" frarpo@sas.com,canepg@sas.com < /dev/null
        echo "No activity detected in the last ${X} hours. We will delete the GKE cluster in $gke"
        #az aks delete --name ${sasid}viya4aks-aks --resource-group $rg --yes
        echo "Now we delete the GKE Cluster..."
        #create unique timestamp
        UTS=$(date '+%s')
        mkdir /tmp/${STUDENT}.${UTS}
        bash scripts/gcp-gen-deletion-script.sh -p ${PROJECT} -s ${STUDENT} -q "true" > /tmp/${STUDENT}.${UTS}/todelete.sh
        bash /tmp/${STUDENT}.${UTS}/todelete.sh
        rm /tmp/${STUDENT}.${UTS}/todelete.sh
    else
        echo "Activity detected in the last ${X} hour for $gk"
        echo "Most Recent Activity: $ActivityInLastXHours"
        #echo "USER: $sasid \n" > /tmp/nodelete.log
        #echo "RG: $rg \n" >> /tmp/nodelete.log
        #echo "UTC Time: ${UTIME} \n" >> /tmp/nodelete.log
        echo "latest GKE detected activity in the last ${X} hours : $ActivityInLastXHours" >> /tmp/nodelete.log
        mail -s "INFO (NO DELETE GKE): for USER: $sasid at ${UTIME}(UTC)" frarpo@sas.com,canepg@sas.com < /tmp/nodelete.log
    fi
    done

