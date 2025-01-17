#!/bin/bash
set -e

echo "START - Building some OpenAPI specs..."
vertag=$(tr -dc A-Za-z0-9 </dev/urandom | head -c 30)
outputUrls=""


# Check if DOC_VERSION environment variable is set and not empty
if [[ ! -z "$DOC_VERSION" ]]; then
    echo "Overriding version with $DOC_VERSION"
    vertag=$DOC_VERSION
else
    echo "Using generated version: $vertag"
fi

echo ""

aws_endpoint=$AWS_ENDPOINT
if [ $aws_endpoint != http* ]
then
  aws_endpoint=https://$aws_endpoint
fi

files=$1
echo $files
for i in $files
do
  outfname=${GITHUB_WORKSPACE}/${i}_${vertag}.html
  fname=$(basename $outfname)
  npx redoc-cli bundle $GITHUB_WORKSPACE/$i -o $outfname --disableGoogleFont --options.expandDefaultServerVariables "true" 
  echo "Copying $outfname to s3://$BUCKET_NAME/$fname"
  aws --endpoint-url $aws_endpoint s3 cp $outfname s3://$BUCKET_NAME/
  aws --endpoint-url $aws_endpoint s3api put-object-acl --bucket $BUCKET_NAME --acl public-read --key $fname
  out="== Uploaded spec successfully to https://${BUCKET_NAME}.${AWS_ENDPOINT}/$fname =="
  ln=${#out}
  while [ $ln -gt 0 ]; do printf '=%.0s'; ((ln--));done;
  echo ""
  echo $out
  ln=${#out}
  while [ $ln -gt 0 ]; do printf '=%.0s'; ((ln--));done;
  echo ""
done

echo "Done generating and uploading OpenAPI specs"
echo ""
