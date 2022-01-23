#!/bin/bash

# Dockerhub user to push bind-docker image
DOCKERHUB_USER=mydockerhubuser


CWD=`pwd`
TMP_FILE=/tmp/generate-hosts.tmp.$$

# sed -i has extra param in OSX
SEDBAK=""

UNAME_OUT="$(uname -s)"
case "${UNAME_OUT}" in
    Linux*)     MACHINE=Linux;;
    Darwin*)    MACHINE=Mac
                SEDBAK=".bak"
                ;;
    CYGWIN*)    MACHINE=Cygwin;;
    MINGW*)     MACHINE=MinGw;;
    *)          MACHINE="UNKNOWN:${UNAME_OUT}"
esac
#echo OS is ${MACHINE}


# ---------------------------------------
# Collect output variables from terraform
# ---------------------------------------
echo ">>> Collecting variables from terraform output.."

cd tf
terraform output > $TMP_FILE
cd $CWD

# Some parsing into shell variables and arrays
DATA=`cat $TMP_FILE |sed "s/'//g"|sed 's/\ =\ /=/g'`
DATA2=`echo $DATA |sed 's/\ *\[/\[/g'|sed 's/\[\ */\[/g'|sed 's/\ *\]/\]/g'|sed 's/\,\ */\,/g'`

for var in `echo $DATA2`
do
  var_name=`echo $var | awk -F"=" '{print $1}'`
  var_value=`echo $var | awk -F"=" '{print $2}'|sed 's/\]//g'|sed 's/\[//g' |sed 's/\"//g'`

  case $var_name in
    "route53_domain")
      BASEDOMAIN=$var_value
      ;;

    "route53_subdomain")
      SUBDOMAIN=$var_value
      ;;

    "cdp-instance-public-ip")
      CDP_IP=$var_value
      ;;

    "cdp-instance-private-ip")
      CDP_PRIVATE_IP=$var_value
      ;;

    "infra-instance-public-ip")
      INFRA_IP=$var_value
      ;;

    "infra-instance-private-ip")
      INFRA_PRIVATE_IP=$var_value
      ;;

    "ecs-node-public-ips")
      COUNT=0
      for entry in $(echo $var_value |sed "s/,/ /g")
      do
        COUNT=$(($COUNT+1))
        ECS_IPS[$COUNT]=$entry
      done
      NUM_ECS_IPS=$COUNT
      ;;

    "ecs-node-private-names")
      COUNT=0
      for entry in $(echo $var_value |sed "s/,/ /g")
      do
        COUNT=$(($COUNT+1))
        ECS_PRIVATE_NAMES[$COUNT]=$entry
      done
      NUM_ECS_PRIVATE_NAMES=$COUNT
      ;;

    "ecs-node-private-ips")
      COUNT=0
      for entry in $(echo $var_value |sed "s/,/ /g")
      do
        COUNT=$(($COUNT+1))
        ECS_PRIVATE_IPS[$COUNT]=$entry
      done
      NUM_ECS_PRIVATE_IPS=$COUNT
      ;;

    "route53-ecs-nodes")
      COUNT=0
      for entry in $(echo $var_value |sed "s/,/ /g")
      do
        COUNT=$(($COUNT+1))
        ECS_NAMES[$COUNT]=$entry
      done
      NUM_ECS_NAMES=$COUNT
      ;;

  esac
done


# Variables
DOMAIN=${SUBDOMAIN}.${BASEDOMAIN}


# ---------------------------------
# Generate hosts file from template
# ---------------------------------
echo ">>> Generating hosts file from hosts.template.."

cp ansible/hosts.template ansible/hosts
sed -i $SEDBAK "s/##BASEDOMAIN##/$BASEDOMAIN/" ansible/hosts
sed -i $SEDBAK "s/##SUBDOMAIN##/$SUBDOMAIN/" ansible/hosts
sed -i $SEDBAK "s/##INFRA_IP##/$INFRA_IP/" ansible/hosts
sed -i $SEDBAK "s/##CDP_IP##/$CDP_IP/" ansible/hosts
sed -i $SEDBAK "s/##DOMAIN##/$DOMAIN/" ansible/hosts
for (( COUNT=1; COUNT<=$NUM_ECS_IPS; COUNT++ ))
do
  echo "ecs${COUNT}  ansible_host=${ECS_IPS[$COUNT]}  fqdn=${ECS_NAMES[$COUNT]}" >> ansible/hosts
done
echo "" >> ansible/hosts


# --------------------------------------------------
# Configure DNS entries for Docker bind-docker image
# --------------------------------------------------
echo ">>> Generating bind-docker/varbind/cdp entries for bind-docker image.."

CDP_IP_NUM=`echo $CDP_PRIVATE_IP |awk -F "." '{print $4}'`
INFRA_IP_NUM=`echo $INFRA_PRIVATE_IP |awk -F "." '{print $4}'`
PRIVATE_SUBNET=`echo ${ECS_PRIVATE_IPS[1]}`
PRIVATE_SUBNET_NET=`echo ${PRIVATE_SUBNET} |awk -F "." '{print $1"."$2"."$3}'`
PRIVATE_SUBNET_REV=`echo $PRIVATE_SUBNET |awk -F "." '{print $3"."$2"."$1}'`
AWS_META_DNS=${PRIVATE_SUBNET}.2
ZONE_CONFIG_DIR=bind-docker/varbind/cdp
DNS_F=${ZONE_CONFIG_DIR}/${DOMAIN}.db
DNS_R=${ZONE_CONFIG_DIR}/db.${PRIVATE_SUBNET_REV}.in-addr.arpa

# subsitute token values in zone config files
cp ${ZONE_CONFIG_DIR}/subdomain.domain.db.template ${DNS_F}
cp ${ZONE_CONFIG_DIR}/db.reversesubnet.in-addr.arpa.template ${DNS_R}
cp bind-docker/configs/named.conf.cdp.template bind-docker/configs/named.conf.cdp
# forward lookup:
sed -i $SEDBAK "s/##DOMAIN##/$DOMAIN/g" ${DNS_F}
sed -i $SEDBAK "s/##INFRA_IP_NUM##/${PRIVATE_SUBNET_NET}.${INFRA_IP_NUM}/g" ${DNS_F}
sed -i $SEDBAK "s/##CDP_IP_NUM##/${PRIVATE_SUBNET_NET}.${CDP_IP_NUM}/g" ${DNS_F}
# reverse lookup:
sed -i $SEDBAK "s/##DOMAIN##/$DOMAIN/g" ${DNS_R}
sed -i $SEDBAK "s/##INFRA_IP_NUM##/$INFRA_IP_NUM/g" ${DNS_R}
sed -i $SEDBAK "s/##CDP_IP_NUM##/$CDP_IP_NUM/g" ${DNS_R}
sed -i $SEDBAK "s/##SUBNET_REV##/$PRIVATE_SUBNET_REV/g" ${DNS_R}
# ecs node entries in both lookups
LOWEST_IP=255
for (( COUNT=1; COUNT<=$NUM_ECS_IPS; COUNT++ ))
do
  ECS_IP_NUM[$COUNT]=`echo ${ECS_PRIVATE_IPS[$COUNT]} |awk -F "." '{print $4}'`
  if (( ${ECS_IP_NUM[$COUNT]} < $LOWEST_IP )) ; then LOWEST_IP=${ECS_IP_NUM[$COUNT]} ; fi
  echo "ecs${COUNT}              IN      A     ${PRIVATE_SUBNET_NET}.${ECS_IP_NUM[$COUNT]}" >> ${DNS_F}
  #sed -i $SEDBAK "s/##ECS${COUNT}_IP_NUM##/${ECS_IP_NUM[$COUNT]}/" ${DNS_R}
  echo "${ECS_IP_NUM[$COUNT]}	 IN	PTR	ecs${COUNT}.$DOMAIN." >> ${DNS_R}
done
## Wildcard DNS entries - lowest IP - override for ecs1 host as can choose in UI wizard
#ECSX_IP=${PRIVATE_SUBNET_NET}.${LOWEST_IP}
ECSX_IP=${PRIVATE_SUBNET_NET}.${ECS_IP_NUM[1]}

sed -i $SEDBAK "s/##ECSX_IP_NUM##/${ECSX_IP}/g" ${DNS_F}
sed -i $SEDBAK "s/##DOMAIN##/${DOMAIN}/g" bind-docker/configs/named.conf.cdp
sed -i $SEDBAK "s/##SUBNET_REV##/${PRIVATE_SUBNET_REV}/g" bind-docker/configs/named.conf.cdp


# ---------------------------------------
# Generate working-files/resolv.conf file
# ---------------------------------------
echo ">>> Generating working-files/resolv.conf.."

cp ansible/working-files/resolv.conf.template ansible/working-files/resolv.conf
sed -i $SEDBAK "s/##INFRA_PRIVATE_IP##/$INFRA_PRIVATE_IP/" ansible/working-files/resolv.conf
sed -i $SEDBAK "s/##DOMAIN##/$DOMAIN/" ansible/working-files/resolv.conf


# ---------------------------------------------------
# Build instance of bind-docker and push to dockerhub
# ---------------------------------------------------
echo ">>> Generating new instance of $DOCKERHUB_USER/bind-docker:$SUBDOMAIN.."

cd bind-docker
docker build -t bind-docker:$SUBDOMAIN .
docker tag bind-docker:$SUBDOMAIN $DOCKERHUB_USER/bind-docker:$SUBDOMAIN
docker push $DOCKERHUB_USER/bind-docker:$SUBDOMAIN
cd $CWD


# --------
# All done
# --------
echo ">>> done."
/bin/rm $TMP_FILE
rm ansible/hosts.bak
rm ansible/working-files/*.bak
rm ${ZONE_CONFIG_DIR}/*.bak
rm bind-docker/configs/*.bak

exit 0

