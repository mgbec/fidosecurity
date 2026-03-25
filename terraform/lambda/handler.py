"""
API Gateway Lambda Handler — bridges public API to AgentCore Orchestrator.
Manages sessions in DynamoDB and invokes the orchestrator agent.
"""

import json
import os
import uuid
import time
import boto3

ORCHESTRATOR_ARN = os.environ["ORCHESTRATOR_ARN"]
SESSIONS_TABLE = os.environ["SESSIONS_TABLE"]
REGION = os.environ.get("AWS_REGION_NAME", "us-west-2")

agentcore = boto3.client("bedrock-agentcore", region_name=REGION)
dynamodb = boto3.resource("dynamodb", region_name=REGION)
table = dynamodb.Table(SESSIONS_TABLE)


def lambda_handler(event, context):
    route = event.get("routeKey", "")
    claims = event.get("requestContext", {}).get("authorizer", {}).get("jwt", {}).get("claims", {})
    user_id = claims.get("sub", "anonymous")

    if route == "POST /advisor":
        return handle_advisor(event, user_id)
    elif route == "GET /sessions":
        return handle_get_sessions(user_id)
    else:
        return response(404, {"error": "Not found"})


def handle_advisor(event, user_id):
    try:
        body = json.loads(event.get("body", "{}"))
    except json.JSONDecodeError:
        return response(400, {"error": "Invalid JSON body"})

    prompt = body.get("prompt", "").strip()
    if not prompt:
        return response(400, {"error": "prompt is required"})

    session_id = body.get("session_id", str(uuid.uuid4()))

    # Invoke orchestrator agent
    try:
        agent_response = agentcore.invoke_agent_runtime(
            agentRuntimeArn=ORCHESTRATOR_ARN,
            qualifier="DEFAULT",
            payload=json.dumps({"prompt": prompt, "user_id": user_id, "session_id": session_id}),
        )

        # Read response
        content_type = agent_response.get("contentType", "")
        result_text = ""

        if "text/event-stream" in content_type:
            for line in agent_response["response"].iter_lines(chunk_size=10):
                if line:
                    decoded = line.decode("utf-8")
                    if decoded.startswith("data: "):
                        decoded = decoded[6:]
                    result_text += decoded
        elif content_type == "application/json":
            chunks = []
            for chunk in agent_response.get("response", []):
                chunks.append(chunk.decode("utf-8"))
            result_data = json.loads("".join(chunks))
            result_text = json.dumps(result_data)
        else:
            result_text = agent_response["response"].read().decode("utf-8")

        # Parse agent response
        try:
            parsed = json.loads(result_text)
            agent_reply = parsed.get("response", result_text)
        except json.JSONDecodeError:
            agent_reply = result_text

        # Store in DynamoDB
        timestamp = time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())
        table.put_item(
            Item={
                "session_id": session_id,
                "timestamp": timestamp,
                "user_id": user_id,
                "prompt": prompt,
                "response": agent_reply[:10000],  # cap stored response size
                "ttl": int(time.time()) + 86400 * 7,  # 7-day TTL
            }
        )

        return response(200, {
            "session_id": session_id,
            "response": agent_reply,
            "timestamp": timestamp,
        })

    except Exception as e:
        return response(500, {"error": str(e)})


def handle_get_sessions(user_id):
    try:
        result = table.query(
            IndexName="user-index",
            KeyConditionExpression="user_id = :uid",
            ExpressionAttributeValues={":uid": user_id},
            ScanIndexForward=False,
            Limit=50,
        )
        items = result.get("Items", [])
        return response(200, {"sessions": items})
    except Exception as e:
        return response(500, {"error": str(e)})


def response(status_code, body):
    return {
        "statusCode": status_code,
        "headers": {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",
        },
        "body": json.dumps(body, default=str),
    }
