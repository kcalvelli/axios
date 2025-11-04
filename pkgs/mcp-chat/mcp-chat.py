#!/usr/bin/env python3
"""
Simple CLI for chatting with Ollama models using MCP tools via mcpo.
Usage: mcp-chat [--model MODEL] [--mcpo-url URL]
"""

import argparse
import json
import sys
import requests
from typing import List, Dict, Any

# Default configuration
DEFAULT_MODEL = "qwen2.5-coder:7b"
DEFAULT_OLLAMA_URL = "http://localhost:11434"
DEFAULT_MCPO_URL = "http://localhost:8000"

# ANSI color codes
class Colors:
    USER = "\033[94m"      # Blue
    ASSISTANT = "\033[92m" # Green
    TOOL = "\033[93m"      # Yellow
    ERROR = "\033[91m"     # Red
    RESET = "\033[0m"
    BOLD = "\033[1m"


def fetch_tools(mcpo_url: str) -> List[Dict[str, Any]]:
    """Fetch tool definitions from all MCP servers via mcpo."""
    tools = []
    server_names = ["journal", "mcp-nixos", "sequential-thinking", "context7", "filesystem"]

    for server in server_names:
        try:
            resp = requests.get(f"{mcpo_url}/{server}/openapi.json", timeout=5)
            if resp.status_code == 200:
                openapi_spec = resp.json()
                # Convert OpenAPI paths to Ollama tool format
                for path, methods in openapi_spec.get("paths", {}).items():
                    for method, details in methods.items():
                        if method.lower() == "post":
                            # Extract tool name from path (remove leading /)
                            tool_name = f"{server}_{path.strip('/').replace('/', '_').replace('.', '_')}"

                            # Build parameters from request body schema
                            schema_ref = details.get("requestBody", {}).get("content", {}).get("application/json", {}).get("schema", {})

                            tools.append({
                                "type": "function",
                                "function": {
                                    "name": tool_name,
                                    "description": details.get("description", f"Call {path} on {server}"),
                                    "parameters": {
                                        "type": "object",
                                        "properties": schema_ref.get("properties", {}),
                                        "required": schema_ref.get("required", [])
                                    }
                                }
                            })
        except Exception as e:
            print(f"{Colors.ERROR}Warning: Failed to fetch tools from {server}: {e}{Colors.RESET}", file=sys.stderr)

    return tools


def call_tool(server: str, endpoint: str, params: Dict[str, Any], mcpo_url: str) -> str:
    """Execute a tool call via mcpo."""
    try:
        url = f"{mcpo_url}/{server}/{endpoint}"
        resp = requests.post(url, json=params, timeout=30)
        resp.raise_for_status()
        return json.dumps(resp.json(), indent=2)
    except Exception as e:
        return f"Error calling tool: {str(e)}"


def chat(model: str, ollama_url: str, mcpo_url: str):
    """Main chat loop."""
    print(f"{Colors.BOLD}MCP Chat{Colors.RESET} - Using model: {model}")
    print(f"Tools available via mcpo at {mcpo_url}")
    print(f"Type 'exit' or 'quit' to end the conversation.\n")

    # Fetch available tools
    print("Loading tools...", end="", flush=True)
    tools = fetch_tools(mcpo_url)
    print(f" {len(tools)} tools loaded.\n")

    messages = []

    while True:
        # Get user input
        try:
            user_input = input(f"{Colors.USER}You:{Colors.RESET} ").strip()
        except (EOFError, KeyboardInterrupt):
            print("\nGoodbye!")
            break

        if user_input.lower() in ["exit", "quit"]:
            print("Goodbye!")
            break

        if not user_input:
            continue

        messages.append({"role": "user", "content": user_input})

        # Call Ollama with tools
        try:
            response = requests.post(
                f"{ollama_url}/api/chat",
                json={
                    "model": model,
                    "messages": messages,
                    "tools": tools,
                    "stream": False
                },
                timeout=120
            )
            response.raise_for_status()
            result = response.json()

            assistant_message = result.get("message", {})
            messages.append(assistant_message)

            # Check if model wants to call tools
            tool_calls = assistant_message.get("tool_calls", [])

            if tool_calls:
                # Execute each tool call
                for tool_call in tool_calls:
                    function = tool_call.get("function", {})
                    tool_name = function.get("name", "")
                    arguments = function.get("arguments", {})

                    print(f"{Colors.TOOL}[Tool Call: {tool_name}]{Colors.RESET}")

                    # Parse tool name to extract server and endpoint
                    # Format: servername_endpoint_parts
                    parts = tool_name.split("_", 1)
                    if len(parts) == 2:
                        server, endpoint = parts
                        endpoint = endpoint.replace("_", ".")

                        result = call_tool(server, endpoint, arguments, mcpo_url)
                        print(f"{Colors.TOOL}[Tool Result]{Colors.RESET}\n{result}\n")

                        # Add tool result to messages
                        messages.append({
                            "role": "tool",
                            "content": result
                        })
                    else:
                        print(f"{Colors.ERROR}Error: Invalid tool name format: {tool_name}{Colors.RESET}")

                # Get final response after tool execution
                response = requests.post(
                    f"{ollama_url}/api/chat",
                    json={
                        "model": model,
                        "messages": messages,
                        "stream": False
                    },
                    timeout=120
                )
                response.raise_for_status()
                result = response.json()
                assistant_message = result.get("message", {})
                messages.append(assistant_message)

            # Print assistant response
            content = assistant_message.get("content", "")
            if content:
                print(f"{Colors.ASSISTANT}Assistant:{Colors.RESET} {content}\n")

        except requests.exceptions.Timeout:
            print(f"{Colors.ERROR}Error: Request timed out{Colors.RESET}\n")
        except requests.exceptions.RequestException as e:
            print(f"{Colors.ERROR}Error: {str(e)}{Colors.RESET}\n")
        except Exception as e:
            print(f"{Colors.ERROR}Unexpected error: {str(e)}{Colors.RESET}\n")


def main():
    parser = argparse.ArgumentParser(description="Chat with Ollama using MCP tools")
    parser.add_argument("--model", default=DEFAULT_MODEL, help=f"Ollama model to use (default: {DEFAULT_MODEL})")
    parser.add_argument("--ollama-url", default=DEFAULT_OLLAMA_URL, help=f"Ollama API URL (default: {DEFAULT_OLLAMA_URL})")
    parser.add_argument("--mcpo-url", default=DEFAULT_MCPO_URL, help=f"MCPO URL (default: {DEFAULT_MCPO_URL})")

    args = parser.parse_args()

    try:
        chat(args.model, args.ollama_url, args.mcpo_url)
    except KeyboardInterrupt:
        print("\nInterrupted by user")
        sys.exit(0)


if __name__ == "__main__":
    main()
