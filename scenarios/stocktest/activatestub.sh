#!/bin/bash

#
# Activate a kubernetes virtual service 
# This is done by saving and overwriting the target service with the stub's service attributes
#

#
# Parse the Parameters
#
TMPFILE=_saved_url

help()
{
  echo 'activatestub.sh PARAMS ...  '
  echo '-n namespace the target namespace'
  echo '-s service name for the service to be actvated in the namespace'
  echo '-t target service name that the virtual service replaces'
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
if [ $? -eq 0 ]
then 
  echo Virtual Service $SERVICENAME appears to be already activated
  exit 0
fi

#
# Make  copy of the service that we are replacing
#
RET=$(oc get svc $TARGETSERVICE -n $NAMESPACE --export=true -o YAML | sed s/$TARGETSERVICE/$DEACTIVATED/g | oc apply -n $NAMESPACE -f - )
if [ $? -ne 0 ]
then
  echo Could not create a safe copy of service $SERVICENAME
  exit 1
fi

#
# Replace the target service with the virtual service attributes (note: this does not yet do port mapping)
#
RET=$(oc get svc $SERVICENAME -n $NAMESPACE --export=true -o YAML | sed s/$SERVICENAME/$TARGETSERVICE/g | oc apply -n $NAMESPACE -f - )
if [ $? -ne 0 ]
then
  echo Could not replace service $TARGETSERVICE with $SERVICENAME
  exit 1
fi

echo Service $SERVICENAME activated as $TARGETSERVICE
