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
APL_CMD_RELEASE=${APL_CMD_RELEASE:-v0.1.0}

set +e

echo "APL_API: $APL_API"
echo
echo "TRAVIS_BRANCH: $TRAVIS_BRANCH"

#if building a tag, make a new release and deploy, if not only doing a deployment
#if [ ! -z "$TRAVIS_TAG" ]; then
#    APL_ARTIFACT_NAME="staging-${TRAVIS_TAG}"
#    CODE_LOC=${TRAVIS_TAG}
#    WORKLOAD_TYPE=level5
#else
#    TRAVIS_COMMIT=`echo $TRAVIS_COMMIT |cut -c 1-12`
#    APL_ARTIFACT_NAME="qa-${TRAVIS_COMMIT}"
#    CODE_LOC=${TRAVIS_COMMIT}
#    WORKLOAD_TYPE=level2
#fi

APL_ARTIFACT_NAME="staging-${TRAVIS_TAG}"
CODE_LOC=${TRAVIS_TAG}
WORKLOAD_TYPE=level5

#APL_ARTIFACT_NAME="${APL_ARTIFACT_NAME}-${TRAVIS_BUILD_NUMBER}"
#APL_ARTIFACT_NAME="${APL_ARTIFACT_NAME}-${TRAVIS_TAG}"
#APL_ARTIFACT_NAME="qa-${TRAVIS_COMMIT}"


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
echo "Submitting stack artifact file:"



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

if [ ! -z "$TRAVIS_TAG" ]; then

    # Each component needs to be packaged as key/value pairs for the --component flag
    mongo_component=(StackComponentID=81b38498-bd49-4b5b-9f51-5bdb2bd9f049)
    mongo_component+=(ServiceName=mongo-service)
    mongo_component+=(StackArtifactID=5549dddb-a0a5-4453-8154-4b126b0a7d0d)
    mongo_component=$(IFS=, ; echo "${mongo_component[*]}")

    node_component=(StackComponentID=${APL_STACK_COMPONENT_ID})
    node_component+=(ServiceName=node-service)
    node_component+=(StackArtifactID=${APL_STACK_ARTIFACT_ID})
    node_component+=(StackArtifactID=7f0b2e90-8757-47ed-bb70-c5c091a0b681)
    node_component+=(StackArtifactID=2f9b4607-1034-446c-817e-ce59b56cc631)
    node_component=$(IFS=, ; echo "${node_component[*]}")

    APL_RELEASE_CREATE_RESULT_JSON=$(./apl releases create -o json \
        --name ${APL_ARTIFACT_NAME} \
        --stack-id ${APL_STACK_ID} \
        --stack-version-id ${APL_STACK_VERSION_ID} \
        --component "${mongo_component}" \
        --component "${node_component}")

    echo
    echo "Result: ${APL_RELEASE_CREATE_RESULT_JSON}"
    if [ $? -ne 0 ]
    then
        echo $APL_RELEASE_CREATE_RESULT_JSON | jq -r '.message'
        exit 1
    fi

    APL_RELEASE_ID=$(echo $APL_RELEASE_CREATE_RESULT_JSON | jq -r '.data')
    echo "Release ID: ${APL_RELEASE_ID}"

    exit 1
fi

echo
echo "Submitting deployment:"

#
# deploy it
    node_component=(StackComponentID=${APL_STACK_COMPONENT_ID})
    node_component+=(ServiceName=node-service)
    node_component+=(StackArtifactID=${APL_STACK_ARTIFACT_ID})
    node_component=$(IFS=, ; echo "${node_component[*]}")

APL_DEPLOY_CREATE_RESULT_JSON=$(./apl deployments create -o json \
    --loc-deploy-id ${APL_LOC_DEPLOY_ID} \
    --name ${APL_ARTIFACT_NAME} \
    --workload-type ${WORKLOAD_TYPE} \
    --release-id ${APL_RELEASE_ID} \
    --component "${node_component}")

echo
echo "Result: ${APL_DEPLOY_CREATE_RESULT_JSON}"
if [ $? -ne 0 ]
then
    echo $APL_DEPLOY_CREATE_RESULT_JSON | jq -r '.message'
    exit 1
fi

# create the stack artifact and get the new ID
APL_DEPLOYMENT_ID=$(echo $APL_DEPLOY_CREATE_RESULT_JSON | jq -r '.data.deployment_id')

echo
echo "Deployment ID: $APL_DEPLOYMENT_ID"