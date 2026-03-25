# Smart Financial Advisor — Multi-Agent AgentCore Application

A public-facing financial advisory application built on Amazon Bedrock AgentCore
with a multi-agent architecture using Python and Strands Agents.

## Architecture

```
User → CloudFront/WAF → API Gateway (Cognito JWT) → Lambda → Orchestrator Agent
                                                                  ├── Research Analyst Agent
                                                                  └── Portfolio Advisor Agent
```

Three agents, each with isolated IAM roles and trust boundaries:

- **Orchestrator** — routes queries, synthesizes responses from specialists
- **Research Analyst** — market data analysis, sector research, asset comparisons
- **Portfolio Advisor** — risk profiling, allocation recommendations, rebalancing

## Scenario: Smart Financial Advisor

Users authenticate via Cognito, submit financial questions through the REST API,
and receive AI-powered analysis. The orchestrator decides which specialist(s) to
invoke based on the query.

### Example Queries

```bash
# Portfolio analysis
curl -X POST $API_ENDPOINT/advisor \
  -H "Authorization: Bearer $JWT" \
  -H "Content-Type: application/json" \
  -d '{"prompt": "I have $500k: 60% in S&P 500 index, 25% in bonds, 15% cash. I am 35 with moderate risk tolerance. Should I rebalance?"}'

# Market research
curl -X POST $API_ENDPOINT/advisor \
  -H "Authorization: Bearer $JWT" \
  -d '{"prompt": "Compare the technology and healthcare sectors over the past year. Which has better risk-adjusted returns?"}'

# Retirement planning
curl -X POST $API_ENDPOINT/advisor \
  -H "Authorization: Bearer $JWT" \
  -d '{"prompt": "I am 45, want to retire at 60, have $800k saved. What allocation strategy should I follow for the next 15 years?"}'

# Retrieve conversation history
curl $API_ENDPOINT/sessions -H "Authorization: Bearer $JWT"
```

## Quick Start

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your region and settings

chmod +x deploy.sh
./deploy.sh
```

Deployment takes ~5-10 minutes (CodeBuild builds ARM64 Docker images for each agent).

## Other Good Scenarios for This Architecture

This same multi-agent pattern works well for:

1. **IT Help Desk** — Orchestrator routes to: Troubleshooting Agent (diagnostics),
   Knowledge Base Agent (documentation search), Ticket Agent (creates/updates tickets)

2. **E-Commerce Shopping Assistant** — Orchestrator routes to: Product Search Agent
   (catalog queries), Recommendation Agent (personalized suggestions),
   Order Agent (status, returns, exchanges)

3. **Healthcare Triage** — Orchestrator routes to: Symptom Checker Agent (initial
   assessment), Scheduling Agent (appointment booking), Insurance Agent (coverage
   verification)

4. **Legal Document Assistant** — Orchestrator routes to: Contract Analyst Agent
   (clause extraction, risk flagging), Research Agent (case law search),
   Compliance Agent (regulatory checks)

5. **Real Estate Advisor** — Orchestrator routes to: Market Analyst Agent (comps,
   trends), Mortgage Agent (rate comparison, affordability), Property Agent
   (listing search, neighborhood data)

## Project Structure

```
terraform/
├── agents/
│   ├── orchestrator/          # Orchestrator agent (Python + Strands)
│   │   ├── agent.py
│   │   ├── Dockerfile
│   │   └── requirements.txt
│   ├── research-analyst/      # Research specialist agent
│   │   ├── agent.py
│   │   ├── Dockerfile
│   │   └── requirements.txt
│   └── portfolio-advisor/     # Portfolio specialist agent
│       ├── agent.py
│       ├── Dockerfile
│       └── requirements.txt
├── lambda/
│   └── handler.py             # API Gateway → AgentCore bridge
├── scripts/                   # Build automation scripts
├── agentcore.tf               # AgentCore runtime resources
├── api_gateway.tf             # HTTP API + Cognito authorizer
├── cloudwatch.tf              # Logging and alarms
├── codebuild.tf               # Docker image build projects
├── cognito.tf                 # User authentication
├── dynamodb.tf                # Session storage
├── ecr.tf                     # Container registries
├── iam.tf                     # Per-agent execution roles
├── lambda.tf                  # Request handler function
├── main.tf                    # Build orchestration
├── outputs.tf                 # Endpoint URLs and ARNs
├── s3.tf                      # Source code storage
├── variables.tf               # Configuration variables
├── versions.tf                # Provider versions
├── buildspec.yml              # Shared CodeBuild spec
├── deploy.sh                  # One-command deploy
├── destroy.sh                 # One-command teardown
└── terraform.tfvars.example   # Example configuration
```

## Cleanup

```bash
cd terraform
./destroy.sh
```
