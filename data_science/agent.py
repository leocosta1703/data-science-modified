# Copyright 2025 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

"""Top level agent for data agent multi-agents.

-- it get data from database (e.g., BQ) using NL2SQL
-- then, it use NL2Py to do further data analysis as needed
"""
import os
from datetime import date

from google.genai import types

from google.adk.agents import Agent, SequentialAgent
from google.adk.agents.callback_context import CallbackContext
from google.adk.tools import load_artifacts, agent_tool

from .sub_agents import db_ds_multiagent 
from .sub_agents.bigquery.tools import (
    get_database_settings as get_bq_database_settings,
)
from .prompts import return_glosa_assistant_instructions_root
from .tools import call_db_agent, call_ds_agent

date_today = date.today()


def setup_before_agent_call(callback_context: CallbackContext):
    """Setup the agent."""

    # setting up database settings in session.state
    if "database_settings" not in callback_context.state:
        db_settings = dict()
        db_settings["use_database"] = "BigQuery"
        callback_context.state["all_db_settings"] = db_settings

    # setting up schema in instruction
    if callback_context.state["all_db_settings"]["use_database"] == "BigQuery":
        callback_context.state["database_settings"] = get_bq_database_settings()
        schema = callback_context.state["database_settings"]["bq_ddl_schema"]

        callback_context._invocation_context.agent.instruction = (
            return_glosa_assistant_instructions_root()
            + f"""

    --------- The BigQuery schema of the relevant data with a few sample rows. ---------
    {schema}

    """
        )

root_agent = Agent(
    model=os.getenv("ROOT_AGENT_MODEL"),
    name="glosa_agent",
    instruction=return_glosa_assistant_instructions_root(),
    global_instruction=(
        f"""
        Você é uma analista de ocorrências de glosas da Rede D'Or. Sua função é gerar uma análise explicando porque a glosa ocorreu.

        Sua resposta deverá ser em formato CSV. Você pode analisar uma glosa somente ou diversas glosas, de acordo com o que for pedido.

        Não deve responder a outros pedidos que não sejam relacionados com análise de glosa. Nesses casos, responda que está fora da sua alçada.

        Só inicie uma análise de glosa se for explicitamente pedido.

        Todays date: {date_today}
        """
    ),
    sub_agents=[],
    tools=[agent_tool.AgentTool(agent=db_ds_multiagent),load_artifacts],
    before_agent_callback=setup_before_agent_call,
    generate_content_config=types.GenerateContentConfig(temperature=0.01),
)
