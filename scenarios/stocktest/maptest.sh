#!/bin/bash

#
# Activate a kubernetes test service mapping
#

#
# Parse the Parameters
#
TMPFILE=_saved_url

help()
{
  echo 'activatestub.sh PARAMS ...  '
  echo '-n namespace the target namespace'
  echo '-s service name for the test to be mapped'
  echo '-t target service to which the test should be mapped'
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
  echo "Missing test service name (option -s)"
  help
fi
if [ -z $TARGETSERVICE ]
then
  echo "Missing target service name (option -o)"
  help
fi


if [ $SERVICENAME -eq $TARGETSERVICE]
then
  exit 0
fi


#
# See if we have already mapped the service
#
RET=$(oc get svc $SERVICENAME -n $NAMESPACE)
if [ $? -eq 0 ]
then 
  echo Test Service $SERVICENAME appears to already exist
  exit 0
fi

#
# Make copy of the target service that we are mapping to with the correct name
#
RET=$(oc get svc $TARGETSERVICE -n $NAMESPACE --export=true -o YAML | sed s/$TARGETSERVICE/$SERVICENAME/g | oc apply -n $NAMESPACE -f - )
if [ $? -ne 0 ]
then
  echo Could not create a test target mapping from $SERVICENAME to $TARGETSERVICE
  exit 1
fi

echo Service $SERVICENAME mapped to $TARGETSERVICE (copied)
