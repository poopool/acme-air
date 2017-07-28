#!/bin/bash
set -e # Exit with nonzero exit code if anything fails

# AppLariat vars
APL_LOC_DEPLOY_ID=${APL_LOC_DEPLOY_ID:?Missing required env var}
APL_LOC_ARTIFACT_ID=${APL_LOC_ARTIFACT_ID:?Missing required env var}
APL_STACK_ID=${APL_STACK_ID:?Missing required env var}
APL_STACK_VERSION_ID=${APL_STACK_VERSION_ID:?Missing required env var}
APL_RELEASE_ID=${APL_RELEASE_ID:?Missing required env var}
APL_STACK_COMPONENT_ID=${APL_STACK_COMPONENT_ID:?Missing required env var}
APL_ARTIFACT_NAME=${APL_ARTIFACT_NAME:?Missing required env var}

APL_DEPLOYMENT_ID=${APL_DEPLOYMENT_ID:?Missing required env var}
APL_CMD_RELEASE=${APL_CMD_RELEASE:-v0.1.0}

set +e

echo "APL_API: $APL_API"
echo
echo "TRAVIS_BRANCH: $TRAVIS_BRANCH"

APL_ARTIFACT_NAME="staging-${TRAVIS_TAG}"
CODE_LOC=${TRAVIS_TAG}
WORKLOAD_TYPE=level5

## Make the name domain safe. // TODO: The API should handle this
APL_ARTIFACT_NAME=${APL_ARTIFACT_NAME//[^A-Za-z0-9\\-]/-}

## Downloading and installing apl cli
APL_FILE=apl-${APL_CMD_RELEASE}-linux_amd64.tgz
if [[ "$OSTYPE" == "darwin"* ]]; then
    APL_FILE=apl-${APL_CMD_RELEASE}-darwin_amd64.tgz
fi
echo
echo "Downloading cli: https://github.com/applariat/go-apl/releases/download/${APL_CMD_RELEASE}/${APL_FILE}"
wget -q https://github.com/applariat/go-apl/releases/download/${APL_CMD_RELEASE}/${APL_FILE}
tar zxf ${APL_FILE}

echo
echo "Creating stack artifact:"

APL_SA_CREATE_RESULT_JSON=$(./apl stack-artifacts create \
    --loc-artifact-id ${APL_LOC_ARTIFACT_ID} \
    --stack-id ${APL_STACK_ID} \
    --stack-artifact-type code \
    --artifact-name https://github.com/poopool/acme-air/archive/${CODE_LOC}.zip \
    --name ${APL_ARTIFACT_NAME} \
    -o json)


echo
echo "Result: ${APL_SA_CREATE_RESULT_JSON}"
if [ $? -ne 0 ]
then
    echo $APL_SA_CREATE_RESULT_JSON | jq -r '.message'
    exit 1
fi

# create the stack artifact and get the new ID
APL_STACK_ARTIFACT_ID=$(echo $APL_SA_CREATE_RESULT_JSON | jq -r '.data')

echo
echo "Stack Artifact ID: ${APL_STACK_ARTIFACT_ID}"

#
# Override artifact
    node_component=(StackComponentID=${APL_STACK_COMPONENT_ID})
    node_component+=(ServiceName=node-service)
    node_component+=(StackArtifactID=${APL_STACK_ARTIFACT_ID})
    node_component=$(IFS=, ; echo "${node_component[*]}")

APL_ARTIFACT_OVERRIDE_RESULT_JSON=$(./apl deployments override $APL_DEPLOYMENT_ID -o json \
    --component "${node_component}")

echo
echo "Result: ${APL_ARTIFACT_OVERRIDE_RESULT_JSON}"
if [ $? -ne 0 ]
then
    echo $APL_ARTIFACT_OVERRIDE_RESULT_JSON | jq -r '.message'
    exit 1
fi

