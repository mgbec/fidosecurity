"""
Portfolio Advisor Agent — Allocation & Risk Assessment Specialist

Handles: portfolio allocation, risk profiling, rebalancing recommendations,
retirement planning scenarios, and tax-efficient strategies.
"""

from strands import Agent, tool
from typing import Dict, Any
from bedrock_agentcore.runtime import BedrockAgentCoreApp

app = BedrockAgentCoreApp()


@tool
def assess_risk_profile(age: int, risk_tolerance: str, investment_horizon: str) -> Dict[str, Any]:
    """
    Assess an investor's risk profile based on demographics and preferences.

    Args:
        age: Investor's age
        risk_tolerance: Self-reported tolerance (conservative, moderate, aggressive)
        investment_horizon: Time horizon (short: <3y, medium: 3-10y, long: >10y)

    Returns:
        Risk profile assessment with recommended allocation ranges
    """
    profiles = {
        "conservative": {"stocks": (20, 40), "bonds": (40, 60), "cash": (10, 20), "alternatives": (0, 10)},
        "moderate": {"stocks": (40, 60), "bonds": (25, 40), "cash": (5, 15), "alternatives": (5, 15)},
        "aggressive": {"stocks": (60, 85), "bonds": (10, 25), "cash": (0, 10), "alternatives": (5, 20)},
    }

    tolerance_key = risk_tolerance.lower()
    if tolerance_key not in profiles:
        tolerance_key = "moderate"

    # Age-based adjustment
    stock_adjustment = max(0, (age - 30) * 0.5)
    profile = profiles[tolerance_key]

    return {
        "age": age,
        "risk_tolerance": tolerance_key,
        "investment_horizon": investment_horizon,
        "recommended_allocation": profile,
        "age_adjustment_note": f"Consider reducing equity by ~{stock_adjustment:.0f}% from upper range due to age",
        "profile_score": round(max(1, min(10, 7 - (age - 30) * 0.1 + {"conservative": -2, "moderate": 0, "aggressive": 2}[tolerance_key])), 1),
    }


@tool
def analyze_portfolio(holdings: str, target_risk: str = "moderate") -> Dict[str, Any]:
    """
    Analyze a portfolio's current allocation and suggest rebalancing.

    Args:
        holdings: Description of current holdings (e.g., "60% stocks, 30% bonds, 10% cash")
        target_risk: Target risk profile (conservative, moderate, aggressive)

    Returns:
        Portfolio analysis with rebalancing recommendations
    """
    return {
        "current_holdings": holdings,
        "target_risk": target_risk,
        "analysis": f"Portfolio analysis against {target_risk} target",
        "recommendations": [
            "Review allocation against target risk profile",
            "Consider tax-loss harvesting opportunities",
            "Evaluate expense ratios of current holdings",
            "Check for sector concentration risk",
        ],
    }


SYSTEM_PROMPT = """You are a Portfolio Advisor specializing in investment allocation and risk management.

Your expertise includes:
- Portfolio construction and asset allocation
- Risk profiling and tolerance assessment
- Rebalancing strategies and timing
- Retirement planning and withdrawal strategies
- Tax-efficient investing approaches
- Diversification analysis

You have tools for risk profiling and portfolio analysis. Use them when the user
provides specific portfolio data, age, or risk preferences.

When making recommendations:
1. Always consider the investor's time horizon and risk tolerance
2. Recommend diversified allocations across asset classes
3. Note tax implications where relevant
4. Suggest specific rebalancing actions when appropriate
5. Include a disclaimer that this is informational, not personalized financial advice

Present recommendations in a clear, actionable format."""


def create_portfolio_advisor() -> Agent:
    return Agent(
        tools=[assess_risk_profile, analyze_portfolio],
        system_prompt=SYSTEM_PROMPT,
        name="PortfolioAdvisorAgent",
    )


@app.entrypoint
async def invoke(payload=None):
    try:
        prompt = payload.get("prompt", "Hello") if payload else "Hello"
        agent = create_portfolio_advisor()
        response = agent(prompt)
        return {
            "status": "success",
            "agent": "portfolio_advisor",
            "response": response.message["content"][0]["text"],
        }
    except Exception as e:
        return {"status": "error", "agent": "portfolio_advisor", "error": str(e)}


if __name__ == "__main__":
    app.run()
