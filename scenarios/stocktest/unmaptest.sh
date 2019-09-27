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
# See if we have already saved the service, which indicates that the operation has already been done
#
RET=$(oc get svc $SERVICENAME -n $NAMESPACE)
if [ $? -ne 0 ]
then 
  echo Test Service $SERVICENAME does not exist
  exit 0
fi

RET=$(oc delete svc $SERVICENAME -n $NAMESPACE)
if [ $? -ne 0 ]
then
  echo Could not remove test target mapping for $SERVICENAME
  exit 1
fi

echo Service $SERVICENAME mapping removed
