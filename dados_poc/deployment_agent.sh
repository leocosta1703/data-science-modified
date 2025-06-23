#!/bin/bash

# Glosa Data Assistant Agent - Link to AgentSpace
# This script links the deployed Glosa Data Assistant agent engine to AgentSpace

# Project configuration
PROJECT_ID="demos-419316"

# Agent Engine details from .env file
REASONING_ENGINE="projects/403273177083/locations/us-central1/reasoningEngines/1319809777517199360"

# Agent details
DISPLAY_NAME="Glosa Data Assistant"
DESCRIPTION="Agente para atuar como assistente na análise das ocorrências de glosa"
TOOL_DESCRIPTION="Este agente realiza a analise de glosas. Glosas são pagamentos que foram negados. A função deste agente é analisar a glosa e explicar o motivo da sua ocorrencia, gerando um arquivo CSV com o resultado da analise"


# AgentSpace app ID
APP_ID="enterprise-search-17489203_1748920341777"

echo "Linking " + ${DISPLAY_NAME} + " to AgentSpace..."
echo "Project ID: ${PROJECT_ID}"
echo "Reasoning Engine: ${REASONING_ENGINE}"
echo "App ID: ${APP_ID}"

# Make the API call to link the agent
curl -X POST \
  -H "Authorization: Bearer $(gcloud auth print-access-token)" \
  -H "Content-Type: application/json" \
  -H "X-Goog-User-Project: ${PROJECT_ID}" \
  "https://discoveryengine.googleapis.com/v1alpha/projects/${PROJECT_ID}/locations/global/collections/default_collection/engines/${APP_ID}/assistants/default_assistant/agents" \
  -d '{
    "displayName": "'"${DISPLAY_NAME}"'",
    "description": "'"${DESCRIPTION}"'",
    "adk_agent_definition": {
      "tool_settings": {
        "tool_description": "'"${TOOL_DESCRIPTION}"'"
      },
      "provisioned_reasoning_engine": {
        "reasoning_engine": "'"${REASONING_ENGINE}"'"
      }
    }
  }'

echo ""
echo "Done! If successful, your Glosa Data Assistant should now be available in AgentSpace."
