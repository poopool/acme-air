#!/bin/bash

TRAVIS_TAG="v1.9.9" \
	APL_LOC_DEPLOY_ID="a1c6ce47-5a0a-4f22-96a6-880271d4a319" \
	APL_LOC_ARTIFACT_ID="c0213faf-4418-48ce-8c20-480cd4303180" \
	APL_STACK_ID="3e87ac7a-fc0b-4f6e-9032-d7aef112c674" \
	APL_RElEASE_ID="5901b92b-2ed2-4f4d-9b45-973103f1b981" \
	APL_STACK_COMPONENT_ID="310018d7-cb69-4d51-abfc-63a33c141039" \
	APL_COMPONENT_SERVICE_ID="ct-deployment" \
	APL_ARTIFACT_NAME="acme-air" \
	APL_CMD_RELEASE="v0.1.8" \
	./deploy.sh
