#!/bin/sh
unamestr=$(uname)

export INTEGRATION_ID=$(avn service integration-list tms-demo-kafka --project $1 --json| jq -r '.[] | select(.integration_type == "flink") | .service_integration_id')

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

SOURCE_TABLE=$(cat source_table.sql)
SINK_TABLE=$(cat sink_table.sql)
STATEMENT=$(cat statement.sql)

APP_JSON=$(jq -r --arg source_table "$SOURCE_TABLE" --arg sink_table "$SINK_TABLE" --arg statement "$STATEMENT" \
'.sources[].create_table |= $source_table | .sinks[].create_table |= $sink_table | .statement |= $statement' \
topology.template.json | envsubst | jq -Rsa .)

export VERSION_ID=$(avn service flink create-application-version tms-demo-flink --project $1 --application-id $APPLICATION_ID """$APP_JSON"""|jq -r '.id')
if [ -z "$VERSION_ID" ]; then
    echo "Failed to deploy application version!"
    exit
fi

# Check if we have running deployment for this Application
DEPLOYMENT_ID=$(avn service flink list-application-deployments tms-demo-flink --project $1 --application-id 3a276971-cbe9-47c6-9ba5-2a7e6d0f0de1|jq -r '.deployments[] | select(.status == "RUNNING") | .id')

if [ ! -z "$DEPLOYMENT_ID" ]; then
    echo "Stop running deployment"
    avn service flink stop-application-deployment tms-demo-flink --project $1 --application-id $APPLICATION_ID --deployment-id $DEPLOYMENT_ID
fi

VERSION_JSON=$(envsubst < deployment.template.json | jq -Rsa .)
avn service flink create-application-deployment tms-demo-flink --project $1 --application-id $APPLICATION_ID """$VERSION_JSON"""
echo "Application deployed succesfully!"
