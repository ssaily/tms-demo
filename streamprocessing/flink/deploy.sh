#!/bin/sh
unamestr=$(uname)

export INTEGRATION_ID=$(avn service integration-list tms-demo-kafka --project ssaily-demo --json| jq -r '.[] | select(.integration_type == "flink") | .service_integration_id')

if [ -z "INTEGRATION_ID" ]; then
    echo "Flink Kafka integration missing. Please check Terraform output!"
    exit
fi

# check if we have an application already
APPLICATION_ID=$(avn service flink list-applications tms-demo-flink --project $1 |jq -r '.applications[] | select(.name == "weather") | .id')
if [ -z "$APPLICATION_ID" ]; then
    echo "Create new application"
    APPLICATION_ID==$(avn service flink create-application tms-demo-flink --project $1 @application.json | jq -r '.id')
else
    echo "Use application $APPLICATION_ID"
fi

if [ "$unamestr" = 'Linux' ]; then

  export $(grep -v '^#' ../../k8s/secrets/aiven/.flink.env | xargs -d '\n')

elif [ "$unamestr" = 'FreeBSD' ] || [ "$unamestr" = 'Darwin' ]; then

  export $(grep -v '^#' ../../k8s/secrets/aiven/.flink.env | xargs -0)

fi
APP_JSON=$(envsubst < topology.template.json | jq -Rsa .)
#echo $APP_JSON
export VERSION_ID=$(avn service flink create-application-version tms-demo-flink --project $1 --application-id $APPLICATION_ID """$APP_JSON"""|jq -r '.id')

if [ -z "$VERSION_ID" ]; then
    echo "Failed to deploy application version"
else
    VERSION_JSON=$(envsubst < deployment.template.json | jq -Rsa .)
    avn service flink create-application-deployment tms-demo-flink --project $1 --application-id $APPLICATION_ID """$VERSION_JSON"""
    echo "Application deployed succesfully!"
fi