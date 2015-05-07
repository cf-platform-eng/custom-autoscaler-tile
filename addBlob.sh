#!/bin/sh

function usage() {
  echo "Error!! Needs 2 arguments: <Path to Blob file> <Directory or folder under ./blobs to save it>"
  echo ""
  echo "Example: ./addBlob.sh my-app.jar autoscaler "
  echo "This would add the 'my-app.jar' as blob under 'blobs/autoscaler' "
  echo ""
}

if [ "$#" -lt 2 ]; then
  usage
  exit -1
fi

givenBlobFile=$1

# The path to the file can have other directories
# Trim the directories
blobFile=`echo $givenBlobFile | awk  -F '/' '{print $NF } '`
blobPath=$2

echo "Removing older versions of the $blobFile previously added"
./removeBlob.sh $blobFile

bosh -n add blob $givenBlobFile $blobPath
bosh -n upload blobs

printf "Is this blob the actual app binary? Respond with y or n:"
read response

if [ "$blobPath" != "cf_cli" ]; then
  PACKAGE_SPEC_FILE=`echo packages/autoscaler/spec`
  blobExists=`grep "$blobPath/$blobFile" $PACKAGE_SPEC_FILE | awk '{print $NF}' `
  if [ "$blobExists" == "" ]; then
    echo "- ${blobPath}/${blobFile}" >> $PACKAGE_SPEC_FILE
  fi
fi

if [ "$response" == "y" ]; then
  app_prefix_name=`echo $blobFile | awk -F . '{ print $1}' `
  app_extn=`echo $blobFile  | awk -F . '{ print $NF}' `

  templateNeedsModification=`grep TEMPLATE_APP jobs/deploy-autoscaler/templates/deploy.sh.erb > /dev/null; echo $?`
  if [ "$templateNeedsModification" == "0" ]; then
    sed -i.bak "s/TEMPLATE_APP_PREFIX_NAME/${app_prefix_name}/g; s/TEMPLATE_APP_EXTENSION/${app_extn}/g" jobs/deploy-autoscaler/templates/deploy.sh.erb
    echo "Modified the jobs/deploy-autoscaler/templates/deloy.sh.erb to refer to the correct app archive or file"
    echo ""
  else
    echo "Could not modify the jobs/*autoscaler/templates/deploy.sh.erb file to refer to the correct app blob bits!!"
    echo "Verify the APP_PREFIX_NAME is set to $app_prefix_name and EXTENSION_NAME is set to $app_extn inside the deploy.sh.erb file"
    echo ""
  fi

  packagingNeedsModification=`grep TEMPLATE_APP packages/autoscaler/packaging > /dev/null; echo $?`
  if [ "$packagingNeedsModification" == "0" ]; then
    sed -i.bak "s/TEMPLATE_APP_BLOB_PATH/${blobPath}/g; s/TEMPLATE_APP_BLOB_FILE/${blobFile}/g" packages/autoscaler/packaging
    echo "Modified the packages/autoscaler/packaging file to refer to the correct app blob bits"
    echo ""
  else
    echo "Could not modify the packages/autoscaler/packaging file to refer to the correct app blob file/path!!"
    echo "Verify $blobPath/$blobFile is specified inside the packages/autoscaler/packaging file"
    echo ""
  fi

fi

find jobs/deploy-autoscaler -name "*.bak" | xargs rm 
find packages/autoscaler -name "*.bak" | xargs rm 

echo ""
