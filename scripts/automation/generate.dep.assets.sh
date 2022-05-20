#!/bin/bash

### sample execution:

# ./generate.dep.assets.sh --help
# ./generate.dep.assets.sh
#    --order <9cdzdd)
#    --cadence-name stable \
#    --cadence-version 2020.0.6 \
#    --order-cli-release 0.2.0
#    --api-key .....
#    --api-secret
#
# https://github.com/sassoftware/viya4-orders-cli/releases/download/0.2.0/viya4-orders-cli_linux_amd64


#### code goes here:

# sytnthax check
while [[ $# -gt 0 ]]; do
    key="$1"
    case ${key} in
        -o|--order)
            shift
            ORDER="${1}"
            shift
            ;;
        -cn|--cadence-name)
            shift
            CADENCE="${1}"
            shift
            ;;
        -cv|--cadence-version)
            shift
            VERSION="${1}"
            shift
            ;;
        -cr|--cadence-release)
            shift
            RELEASE="${1}"
            shift
            ;;
        -ocr|--order-cli-release)
            shift
            ORDERCLIRELEASE="${1}"
            shift
            ;;
        -ak|--api-key)
            shift
            APIKEY="${1}"
            shift
            ;;
        -as|--api-secret)
            shift
            APISECRET="${1}"
            shift
            ;;
        -gk|--gelweb-key)
            shift
            GELWEB_KEY="${1}"
            shift
            ;;
        *)
            echo -e "\n\nOne or more arguments were not recognized: \n$@"
            echo
            exit 1
            shift
    ;;
    esac
done

# get the ordercli binary
echo "Downloading the order CLI ${ORDERCLIRELEASE}"
curl -k -L https://github.com/sassoftware/viya4-orders-cli/releases/download/${ORDERCLIRELEASE}/viya4-orders-cli_linux_amd64 \
    -o orders-cli
# set exec perms
chmod u+x orders-cli
# encode Key and secret



export CLIENTCREDENTIALSID=$(echo -n ${APIKEY} | base64)
export CLIENTCREDENTIALSSECRET=$(echo -n ${APISECRET} | base64)
# run the order cli to download deployment assets
echo "Downloading deployment assets"
echo "orders-cli dep $ORDER $CADENCE $VERSION"
./orders-cli dep $ORDER $CADENCE $VERSION | tee order-cli-output.txt

LATESTORDER=$(grep "AssetLocation" order-cli-output.txt | awk -F '/' '{ print $NF }')
echo "downloaded order: $LATESTORDER"

# Check if the order is already there or not in gelweb
orderfound=0
GELWEB_ORDERS_FOL=https://gelweb.race.sas.com/scripts/PSGEL255/orders/
for order in $(curl -k -s  ${GELWEB_ORDERS_FOL} | grep  -E -o ${LATESTORDER});  \
        do
        echo "Found order called $order"
        orderfound=1
    done

if [ "$orderfound" -eq 0 ]; then
    echo "Upload latest order deployment assets ${LATESTORDER} on gelweb"
    echo scp -o StrictHostKeyChecking=no -i "${GELWEB_KEY}" ${LATESTORDER}  glsuser1@gelweb.race.sas.com:/r/nagel01/vol/gel/gate/workshops/SCRIPTS/PSGEL255/orders/ | tee scp.txt
    scp -o StrictHostKeyChecking=no -i "${GELWEB_KEY}" ${LATESTORDER}  glsuser1@gelweb.race.sas.com:/r/nagel01/vol/gel/gate/workshops/SCRIPTS/PSGEL255/orders/
else
    echo "the order deployment asset ${LATESTORDER} is already on the gelweb server"
fi

# clean up
#ls -l SASViyaV4_${ORDER}_${CADENCE}_* | sort

echo "generate cleanup script"

printf "
#!/bin/bash

cd /r/nagel01/vol/gel/gate/workshops/SCRIPTS/PSGEL255/orders/

for f in \$(ls SASViyaV4_${ORDER}*${CADENCE}_${VERSION}* | sort | head -n -1)
    do
    mv \$f archive
done

" > ./keeplast.sh



echo "uploading cleanup script"
scp -o StrictHostKeyChecking=no -i "${GELWEB_KEY}" ./keeplast.sh  glsuser1@gelweb.race.sas.com:/r/nagel01/vol/gel/gate/workshops/SCRIPTS/PSGEL255/orders/

echo "Remove older versions of the deployment asset"
echo "Remove old version of ${ORDER} for ${CADENCE} ${VERSION}"

#ssh -v -o StrictHostKeyChecking=no -i "${GELWEB_KEY}" glsuser1@gelweb.race.sas.com 'chmod 755 /r/nagel01/vol/gel/gate/workshops/SCRIPTS/PSGEL255/orders/keeplast.sh'

ssh -v -o StrictHostKeyChecking=no -i "${GELWEB_KEY}" glsuser1@gelweb.race.sas.com '/r/nagel01/vol/gel/gate/workshops/SCRIPTS/PSGEL255/orders/keeplast.sh '


# testing it
# ./generate.dep.assets.sh \
#     --order 9CDZDD \
#     --cadence-name lts \
#     --cadence-version 2020.1 \
#     --order-cli-release 1.0.0 \
#     --api-key otHGJtno8QGTqys9vRGxmgLOCnVsHWG2 \
#     --api-secret banKYbGZyNkDXbBO

# testing it (ALREADY THERE)
# ./generate.dep.assets.sh \
#     --order 9CF3T6 \
#     --cadence-name lts \
#     --cadence-version 2020.1 \
#     --order-cli-release 1.0.0 \
#     --api-key otHGJtno8QGTqys9vRGxmgLOCnVsHWG2 \
#     --api-secret banKYbGZyNkDXbBO