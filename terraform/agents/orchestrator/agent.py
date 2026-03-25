"""
Orchestrator Agent — Smart Financial Advisor

Routes user queries to specialist agents:
  - Research Analyst: market data, sector analysis, financial research
  - Portfolio Advisor: allocation recommendations, risk assessment, rebalancing
"""

from strands import Agent, tool
from typing import Dict, Any
import boto3
import json
import os
from bedrock_agentcore.runtime import BedrockAgentCoreApp

app = BedrockAgentCoreApp()

RESEARCH_ANALYST_ARN = os.environ.get("RESEARCH_ANALYST_ARN", "")
PORTFOLIO_ADVISOR_ARN = os.environ.get("PORTFOLIO_ADVISOR_ARN", "")
REGION = os.environ.get("AWS_REGION", "us-west-2")


def _invoke_agent(arn: str, query: str) -> str:
    """Invoke a downstream agent runtime and return its response text."""
    try:
        client = boto3.client("bedrock-agentcore", region_name=REGION)
        resp = client.invoke_agent_runtime(
            agentRuntimeArn=arn,
            qualifier="DEFAULT",
            payload=json.dumps({"prompt": query}),
        )

        content_type = resp.get("contentType", "")
        if "text/event-stream" in content_type:
            parts = []
            for line in resp["response"].iter_lines(chunk_size=10):
                if line:
                    decoded = line.decode("utf-8")
                    if decoded.startswith("data: "):
                        decoded = decoded[6:]
                    parts.append(decoded)
            return "".join(parts)
        elif content_type == "application/json":
            chunks = [c.decode("utf-8") for c in resp.get("response", [])]
            return "".join(chunks)
        else:
            return resp["response"].read().decode("utf-8")
    except Exception as e:
        return f"Error invoking agent: {e}"


@tool
def call_research_analyst(query: str) -> Dict[str, Any]:
    """
    Call the Research Analyst agent for market data analysis, sector research,
    financial news interpretation, and economic trend analysis.

    Args:
        query: The research question or data analysis request

    Returns:
        Research analyst's findings and analysis
    """
    result = _invoke_agent(RESEARCH_ANALYST_ARN, query)
    return {"status": "success", "source": "research_analyst", "content": [{"text": result}]}


@tool
def call_portfolio_advisor(query: str) -> Dict[str, Any]:
    """
    Call the Portfolio Advisor agent for portfolio allocation recommendations,
    risk assessment, rebalancing suggestions, and investment strategy advice.

    Args:
        query: The portfolio question, including any holdings data or risk preferences

    Returns:
        Portfolio advisor's recommendations
    """
    result = _invoke_agent(PORTFOLIO_ADVISOR_ARN, query)
    return {"status": "success", "source": "portfolio_advisor", "content": [{"text": result}]}


SYSTEM_PROMPT = """You are a Smart Financial Advisor orchestrator.

Your job is to understand the user's financial question and delegate to the right specialist:

1. **Research Analyst** (call_research_analyst) — Use for:
   - Market data analysis and interpretation
   - Sector and industry research
   - Economic trend analysis
   - Company or asset class comparisons
   - News impact assessment

2. **Portfolio Advisor** (call_portfolio_advisor) — Use for:
   - Portfolio allocation recommendations
   - Risk assessment and tolerance matching
   - Rebalancing suggestions
   - Retirement planning scenarios
   - Tax-efficient investment strategies

For complex queries, you may call BOTH specialists and synthesize their responses.
For simple greetings or clarification questions, respond directly.

Always present the final answer in a clear, structured format with actionable insights.
Include appropriate disclaimers that this is informational, not personalized financial advice."""


def create_orchestrator() -> Agent:
    return Agent(
        tools=[call_research_analyst, call_portfolio_advisor],
        system_prompt=SYSTEM_PROMPT,
        name="OrchestratorAgent",
    )


@app.entrypoint
async def invoke(payload=None):
    try:
        prompt = payload.get("prompt", "Hello") if payload else "Hello"
        agent = create_orchestrator()
        response = agent(prompt)
        return {
            "status": "success",
            "agent": "orchestrator",
            "response": response.message["content"][0]["text"],
        }
    except Exception as e:
        return {"status": "error", "agent": "orchestrator", "error": str(e)}


if __name__ == "__main__":
    app.run()
