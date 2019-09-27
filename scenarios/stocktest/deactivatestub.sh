#!/bin/bash

#
# Deactivate a virtual service stub in Kubernetes
# This is done by saving and overwriting a target service with the stub's service attributes
#

#
# Parse the Parameters
#
TMPFILE=_saved_url

help()
{
  echo 'activatestub.sh PARAMS ...  '
  echo '-n namespace the target namespace'
  echo '-s service name for the service to be deactivated in the namespace'
  echo '-t target service name that should be returned to its native state'
  echo '-h this message. Help message'
  exit 1
}

while getopts n:s:t:h option
do
  case "${option}"
  in
    n) NAMESPACE=${OPTARG};;
    s) SERVICENAME=${OPTARG};;
    t) TARGETSERVICE=${OPTARG};;
    h)
      help
      ;;
    :)
      echo "option $OPTARG needs a value"
      help
      ;;
    \?)
      echo "$OPTARG : invalid option"
      help
      ;;
  esac
done

if [ -z $NAMESPACE ]
then
  echo "Missing namespace (option -n)"
  help
fi
if [ -z $SERVICENAME ]
then
  echo "Missing virtual service name (option -s)"
  help
fi
if [ -z $TARGETSERVICE ]
then
  echo "Missing target service name (option -o)"
  help
fi

DEACTIVATED=deactivated-$TARGETSERVICE

#
# See if we have already saved the target service, which indicates that the operation has already been done
#
RET=$(oc get svc $DEACTIVATED -n $NAMESPACE)
if [ $? -ne 0 ]
then 
  echo Virtual Service $SERVICENAME does not appear to be activated
  exit 1
fi

#
# Replace the original version of the service 
#
RET=$(oc delete svc -n $NAMESPACE $TARGETSERVICE)
RET=$(oc get svc $DEACTIVATED -n $NAMESPACE --export=true -o YAML | sed s/$DEACTIVATED/$TARGETSERVICE/g | oc apply -n $NAMESPACE -f - )
if [ $? -ne 0 ]
then
  echo Could not copy service $DEACTIVATED back to $TARGETSERVICE
  exit 1
fi

#
# Delete the saved copy of the service
#
RET=$(oc delete svc $DEACTIVATED -n $NAMESPACE )
if [ $? -ne 0 ]
then
  echo Could not delete saved service $DEACTIVATED
  exit 1
fi

echo Service $SERVICENAME deactivated
