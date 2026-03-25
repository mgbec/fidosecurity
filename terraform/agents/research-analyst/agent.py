"""
Research Analyst Agent — Market Data & Financial Research Specialist

Handles: sector analysis, market trends, economic indicators,
asset class comparisons, and financial news interpretation.
"""

from strands import Agent, tool
from typing import Dict, Any
from bedrock_agentcore.runtime import BedrockAgentCoreApp

app = BedrockAgentCoreApp()


@tool
def analyze_market_data(sector: str, timeframe: str = "1Y") -> Dict[str, Any]:
    """
    Analyze market data for a given sector over a timeframe.

    Args:
        sector: Market sector (e.g., "technology", "healthcare", "energy")
        timeframe: Analysis period (e.g., "1M", "3M", "1Y", "5Y")

    Returns:
        Market analysis data for the sector
    """
    # In production, this would call a market data API
    return {
        "sector": sector,
        "timeframe": timeframe,
        "analysis": f"Market analysis for {sector} over {timeframe}",
        "note": "Connect to a real market data provider for live data",
    }


@tool
def compare_assets(assets: str, metric: str = "returns") -> Dict[str, Any]:
    """
    Compare multiple assets or asset classes on a given metric.

    Args:
        assets: Comma-separated list of assets (e.g., "SPY,QQQ,BND")
        metric: Comparison metric (returns, volatility, sharpe_ratio, correlation)

    Returns:
        Comparative analysis of the specified assets
    """
    asset_list = [a.strip() for a in assets.split(",")]
    return {
        "assets": asset_list,
        "metric": metric,
        "comparison": f"Comparison of {', '.join(asset_list)} by {metric}",
        "note": "Connect to a real data provider for live comparisons",
    }


SYSTEM_PROMPT = """You are a Research Analyst specializing in financial markets.

Your expertise includes:
- Market sector analysis and trends
- Economic indicator interpretation
- Asset class performance comparison
- Risk factor identification
- Historical pattern analysis

You have access to tools for market data analysis and asset comparison.
Use them when the user provides specific sectors, tickers, or asks for data-driven analysis.

For general knowledge questions about markets, respond from your training knowledge.

Always be precise with data, cite timeframes, and note when data may be approximate.
Present findings in a structured format with key takeaways."""


def create_research_analyst() -> Agent:
    return Agent(
        tools=[analyze_market_data, compare_assets],
        system_prompt=SYSTEM_PROMPT,
        name="ResearchAnalystAgent",
    )


@app.entrypoint
async def invoke(payload=None):
    try:
        prompt = payload.get("prompt", "Hello") if payload else "Hello"
        agent = create_research_analyst()
        response = agent(prompt)
        return {
            "status": "success",
            "agent": "research_analyst",
            "response": response.message["content"][0]["text"],
        }
    except Exception as e:
        return {"status": "error", "agent": "research_analyst", "error": str(e)}


if __name__ == "__main__":
    app.run()
