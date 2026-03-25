# Public-Facing Multi-Agent AgentCore Architecture

```mermaid
flowchart TB
    subgraph Internet["Internet (Public)"]
        User["👤 End User<br/>(Browser / Mobile App)"]
    end

    subgraph Edge["Edge & CDN"]
        CF["Amazon CloudFront<br/>(CDN / WAF Integration)"]
        WAF["AWS WAF<br/>(Rate Limiting, IP Filtering,<br/>Bot Protection)"]
    end

    subgraph Auth["Authentication Layer"]
        Cognito["Amazon Cognito<br/>(User Pool + Identity Pool)<br/>OAuth 2.0 / OIDC / SAML"]
    end

    subgraph API["API Layer"]
        APIGW["Amazon API Gateway<br/>(REST/WebSocket API)<br/>Throttling, API Keys,<br/>Usage Plans"]
    end

    subgraph Compute["Application Compute"]
        Lambda["AWS Lambda<br/>(Request Handler /<br/>Session Manager)"]
    end

    subgraph AgentCoreRuntime["Amazon Bedrock AgentCore Runtime"]
        direction TB

        subgraph Orchestrator["Orchestrator Agent Runtime"]
            OAgent["🤖 Orchestrator Agent<br/>(Routes & Delegates)"]
            ORole["IAM Execution Role<br/>• bedrock:InvokeModel<br/>• bedrock-agentcore:InvokeAgentRuntime<br/>• bedrock-agentcore:GetWorkloadAccessToken"]
        end

        subgraph Specialist1["Specialist Agent 1 Runtime"]
            S1Agent["🤖 Data Analysis Agent"]
            S1Role["IAM Execution Role<br/>• bedrock:InvokeModel<br/>• s3:GetObject (data bucket)<br/>• bedrock-agentcore:GetWorkloadAccessToken"]
        end

        subgraph Specialist2["Specialist Agent 2 Runtime"]
            S2Agent["🤖 Customer Service Agent"]
            S2Role["IAM Execution Role<br/>• bedrock:InvokeModel<br/>• dynamodb:Query/PutItem<br/>• bedrock-agentcore:GetWorkloadAccessToken"]
        end

        subgraph Specialist3["Specialist Agent 3 Runtime"]
            S3Agent["🤖 External API Agent"]
            S3Role["IAM Execution Role<br/>• bedrock:InvokeModel<br/>• bedrock-agentcore:GetResourceOauth2Token<br/>• secretsmanager:GetSecretValue"]
        end
    end

    subgraph Identity["AgentCore Identity"]
        WID["Workload Identity Directory"]
        TokenVault["Token Vault<br/>(OAuth2 Credential Providers)"]
    end

    subgraph Policy["AgentCore Policy"]
        PolicyEngine["Cedar Policy Engine<br/>(forbid-overrides-permit)"]
    end

    subgraph Gateway["AgentCore Gateway"]
        GW["MCP Gateway<br/>(Tool Proxy + Policy Enforcement)"]
    end

    subgraph AI["Amazon Bedrock"]
        Models["Foundation Models<br/>(Claude, etc.)"]
    end

    subgraph Storage["Data & Storage"]
        DDB["Amazon DynamoDB<br/>(Session State,<br/>Conversation History)"]
        S3["Amazon S3<br/>(Documents, Data,<br/>Agent Artifacts)"]
    end

    subgraph Secrets["Secrets & Config"]
        SM["AWS Secrets Manager<br/>(API Keys, OAuth Secrets)"]
        SSM["AWS Systems Manager<br/>Parameter Store"]
    end

    subgraph Monitoring["Observability"]
        CW["Amazon CloudWatch<br/>(Logs, Metrics,<br/>Alarms)"]
        XRay["AWS X-Ray<br/>(Distributed Tracing)"]
    end

    subgraph Containers["Container Registry"]
        ECR["Amazon ECR<br/>(Agent Container Images)"]
    end

    subgraph Network["Network Security"]
        VPC["Amazon VPC<br/>(Private Subnets,<br/>Security Groups)"]
        VPCE["VPC Endpoints<br/>(PrivateLink)"]
    end

    subgraph ExternalSvc["External Services"]
        ExtAPI["3rd Party APIs<br/>(CRM, Payment, etc.)"]
    end

    %% Request Flow
    User -->|"HTTPS"| CF
    CF -->|"Filtered Traffic"| WAF
    WAF -->|"Clean Traffic"| APIGW
    User -->|"Auth Flow"| Cognito
    Cognito -->|"JWT Token"| User
    APIGW -->|"Cognito Authorizer<br/>validates JWT"| Cognito
    APIGW -->|"Authorized Request"| Lambda

    %% Lambda to AgentCore
    Lambda -->|"InvokeAgentRuntime<br/>(SigV4 signed)"| OAgent

    %% Orchestrator Delegation
    OAgent -->|"InvokeAgentRuntime"| S1Agent
    OAgent -->|"InvokeAgentRuntime"| S2Agent
    OAgent -->|"InvokeAgentRuntime"| S3Agent

    %% Model Access
    OAgent -->|"InvokeModel"| Models
    S1Agent -->|"InvokeModel"| Models
    S2Agent -->|"InvokeModel"| Models
    S3Agent -->|"InvokeModel"| Models

    %% Tool Access via Gateway
    S1Agent -->|"MCP tool calls"| GW
    S2Agent -->|"MCP tool calls"| GW
    S3Agent -->|"MCP tool calls"| GW
    GW -->|"Evaluate every<br/>tool call"| PolicyEngine

    %% Identity
    S3Agent -->|"Get OAuth2 Token<br/>(User Federation)"| WID
    WID --- TokenVault
    TokenVault -->|"Retrieve Secret"| SM

    %% Data Access
    S1Agent --> S3
    S2Agent --> DDB
    Lambda --> DDB

    %% External
    S3Agent -->|"Authenticated<br/>API calls"| ExtAPI

    %% Container Images
    ECR -->|"Pull Images"| AgentCoreRuntime

    %% Observability
    AgentCoreRuntime -->|"Logs & Metrics"| CW
    AgentCoreRuntime -->|"Traces"| XRay

    %% Network
    AgentCoreRuntime -.->|"Private<br/>Connectivity"| VPC
    VPC --- VPCE

    %% Styling
    classDef aws fill:#FF9900,stroke:#232F3E,color:#232F3E,font-weight:bold
    classDef agent fill:#7B68EE,stroke:#232F3E,color:white,font-weight:bold
    classDef security fill:#DD3522,stroke:#232F3E,color:white,font-weight:bold
    classDef user fill:#2E86C1,stroke:#232F3E,color:white,font-weight:bold
    classDef external fill:#27AE60,stroke:#232F3E,color:white,font-weight:bold

    class CF,APIGW,Lambda,DDB,S3,SM,SSM,CW,XRay,ECR aws
    class OAgent,S1Agent,S2Agent,S3Agent agent
    class WAF,Cognito,PolicyEngine,WID,TokenVault,VPC,VPCE security
    class User user
    class ExtAPI external
```

## Request Flow (numbered)

```
1. User authenticates via Amazon Cognito (OAuth 2.0 / OIDC)
2. User sends request → CloudFront → WAF (bot/DDoS filtering) → API Gateway
3. API Gateway validates JWT via Cognito Authorizer
4. Lambda handler manages session, calls bedrock-agentcore:InvokeAgentRuntime (SigV4)
5. Orchestrator Agent receives request, reasons with Bedrock FM
6. Orchestrator delegates to Specialist Agent(s) via InvokeAgentRuntime
7. Specialist agents access tools through AgentCore Gateway
8. Cedar Policy Engine evaluates every tool call (default-deny)
9. For external APIs, AgentCore Identity brokers OAuth2 tokens per-user
10. Results flow back: Specialist → Orchestrator → Lambda → API GW → User
```

## IAM Trust Boundaries

```
┌─────────────────────────────────────────────────────────────────────┐
│ BOUNDARY 1: Internet → AWS (CloudFront + WAF + API Gateway)        │
│  • TLS termination, DDoS protection, rate limiting                 │
│  • Cognito JWT validation at API Gateway                           │
└─────────────────────────────────────────────────────────────────────┘
        │
┌─────────────────────────────────────────────────────────────────────┐
│ BOUNDARY 2: Application → AgentCore (Lambda → Runtime)             │
│  • Lambda role needs: bedrock-agentcore:InvokeAgentRuntime          │
│  • Scoped to orchestrator agent ARN only                           │
│  • SigV4 signed — no bearer tokens crossing this boundary          │
└─────────────────────────────────────────────────────────────────────┘
        │
┌─────────────────────────────────────────────────────────────────────┐
│ BOUNDARY 3: Orchestrator → Specialists (Agent-to-Agent)            │
│  • Only orchestrator role has InvokeAgentRuntime permission         │
│  • Specialists CANNOT call back to orchestrator or each other      │
│  • Each agent assumes its OWN role — no credential forwarding      │
│  • Directed acyclic delegation graph                               │
└─────────────────────────────────────────────────────────────────────┘
        │
┌─────────────────────────────────────────────────────────────────────┐
│ BOUNDARY 4: Agents → Tools (AgentCore Gateway + Cedar Policy)      │
│  • Every MCP tool call intercepted by Gateway                      │
│  • Cedar evaluates: principal (user) × action (tool) × context     │
│  • Default-deny, forbid-overrides-permit                           │
│  • Tool-level authorization independent of IAM                     │
└─────────────────────────────────────────────────────────────────────┘
        │
┌─────────────────────────────────────────────────────────────────────┐
│ BOUNDARY 5: Agents → External Services (AgentCore Identity)        │
│  • OAuth2 tokens scoped per-user, per-session                      │
│  • Token Vault manages lifecycle (refresh, revocation)             │
│  • Agent never sees raw client secrets                             │
│  • User must explicitly consent (USER_FEDERATION flow)             │
└─────────────────────────────────────────────────────────────────────┘
```

## AWS Services Summary

| Category | Service | Purpose |
|----------|---------|---------|
| Edge | CloudFront | CDN, TLS termination, geographic routing |
| Security | AWS WAF | Bot protection, rate limiting, IP filtering |
| Auth | Amazon Cognito | User authentication, JWT issuance, OAuth 2.0 |
| API | API Gateway | REST/WebSocket API, throttling, Cognito authorizer |
| Compute | AWS Lambda | Request handling, session management |
| AI Runtime | Bedrock AgentCore Runtime | Hosts agent containers, manages agent lifecycle |
| AI Models | Amazon Bedrock | Foundation model inference (Claude, etc.) |
| Agent Identity | AgentCore Identity | Workload identity, OAuth2 token brokering |
| Agent Policy | AgentCore Policy | Cedar-based tool-level authorization |
| Agent Gateway | AgentCore Gateway | MCP tool proxy, policy enforcement point |
| Containers | Amazon ECR | Agent Docker image storage |
| Database | Amazon DynamoDB | Session state, conversation history |
| Storage | Amazon S3 | Documents, data, agent artifacts |
| Secrets | Secrets Manager | OAuth client secrets, API keys |
| Config | SSM Parameter Store | Runtime configuration |
| Logging | Amazon CloudWatch | Logs, metrics, alarms |
| Tracing | AWS X-Ray | Distributed tracing across agents |
| Network | Amazon VPC | Private subnets for agent-to-data connectivity |
| Network | VPC Endpoints | PrivateLink for AWS service access without internet |
| IAM | AWS IAM | Per-agent execution roles, trust policies |
