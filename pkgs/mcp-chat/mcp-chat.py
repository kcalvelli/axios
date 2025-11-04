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
                server_info = openapi_spec.get("info", {})
                server_title = server_info.get("title", server)

                # Convert OpenAPI paths to Ollama tool format
                for path, methods in openapi_spec.get("paths", {}).items():
                    for method, details in methods.items():
                        if method.lower() == "post":
                            # Extract tool name from path (remove leading /)
                            endpoint = path.strip('/').replace('.', '_')
                            tool_name = f"{server}_{endpoint}"

                            # Build parameters from request body schema
                            schema_ref = details.get("requestBody", {}).get("content", {}).get("application/json", {}).get("schema", {})

                            # Get reference to actual schema if using $ref
                            if "$ref" in schema_ref:
                                ref_path = schema_ref["$ref"].split("/")
                                schema_obj = openapi_spec
                                for part in ref_path:
                                    if part == "#":
                                        continue
                                    schema_obj = schema_obj.get(part, {})
                                schema_ref = schema_obj

                            # Create enhanced description with specific keywords
                            base_desc = details.get("description", "").strip()
                            summary = details.get("summary", "")

                            # Add specific context for journal tools
                            if server == "journal":
                                if "tail" in endpoint or "tail" in path:
                                    enhanced_desc = "Query recent systemd journal logs (last N entries). Use this for 'show recent logs', 'latest logs', etc. " + base_desc
                                elif "query" in endpoint or "query" in path:
                                    enhanced_desc = "Query systemd journal with filters (unit, priority, time range, grep). Use for specific log searches. " + base_desc
                                elif "status" in endpoint or "status" in path:
                                    enhanced_desc = "Get systemd unit status. Use for checking if a service is running. " + base_desc
                                else:
                                    enhanced_desc = f"[Systemd Journal] {base_desc}"
                            # Add context for filesystem tools
                            elif server == "filesystem":
                                enhanced_desc = f"[File Operations] {base_desc}. Use for reading/writing files, NOT for systemd logs."
                            # Default format for other servers
                            else:
                                enhanced_desc = f"[{server_title}] {base_desc}"
                                if summary:
                                    enhanced_desc = f"[{server_title}] {summary}: {base_desc}"

                            tools.append({
                                "type": "function",
                                "function": {
                                    "name": tool_name,
                                    "description": enhanced_desc,
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

    # Add system message to encourage tool use
    messages = [{
        "role": "system",
        "content": """You are a helpful assistant with access to tools. When the user asks questions that can be answered using the available tools, you MUST use them instead of providing manual instructions.

Guidelines:
- For systemd logs or journal queries: Use journal_logs_tail or journal_logs_query tools
- For file operations: Use filesystem tools
- For NixOS packages: Use mcp-nixos tools
- NEVER tell users to run journalctl, cat, or other commands manually when you have tools available
- Always use the appropriate tool for the task"""
    }]

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

            # Check if model wants to call tools
            tool_calls = assistant_message.get("tool_calls", [])

            # Some models return tool calls as JSON in content instead of tool_calls field
            # Try to parse content as JSON tool call if no tool_calls found
            if not tool_calls:
                content = assistant_message.get("content", "").strip()
                if content.startswith("{") and ("name" in content or "function" in content):
                    try:
                        parsed = json.loads(content)
                        # Convert to tool_calls format
                        if "name" in parsed and "arguments" in parsed:
                            tool_calls = [{
                                "function": {
                                    "name": parsed["name"],
                                    "arguments": parsed.get("arguments", {})
                                }
                            }]
                            # Don't append this message yet, wait for tool execution
                        else:
                            messages.append(assistant_message)
                    except json.JSONDecodeError:
                        messages.append(assistant_message)
                else:
                    messages.append(assistant_message)
            else:
                messages.append(assistant_message)

            if tool_calls:
                # Execute each tool call
                for tool_call in tool_calls:
                    function = tool_call.get("function", {})
                    tool_name = function.get("name", "")
                    arguments = function.get("arguments", {})

                    print(f"{Colors.TOOL}[Tool Call: {tool_name}]{Colors.RESET}")
                    print(f"{Colors.TOOL}[Arguments: {json.dumps(arguments, indent=2)}]{Colors.RESET}")

                    # Parse tool name to extract server and endpoint
                    # Format: servername_endpoint_parts
                    parts = tool_name.split("_", 1)
                    if len(parts) >= 2:
                        server = parts[0]
                        endpoint = "_".join(parts[1:]).replace("_", ".")

                        tool_result = call_tool(server, endpoint, arguments, mcpo_url)
                        print(f"{Colors.TOOL}[Tool Result]{Colors.RESET}\n{tool_result}\n")

                        # Add tool result to messages
                        messages.append({
                            "role": "tool",
                            "content": tool_result
                        })
                    else:
                        error_msg = f"Invalid tool name format: {tool_name}. Expected format: servername_endpoint"
                        print(f"{Colors.ERROR}Error: {error_msg}{Colors.RESET}")
                        messages.append({
                            "role": "tool",
                            "content": f"Error: {error_msg}"
                        })

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
    parser.add_argument("--list-tools", action="store_true", help="List available tools and exit")
    parser.add_argument("-q", "--query", type=str, help="Execute a single query and exit (non-interactive mode)")

    args = parser.parse_args()

    # List tools mode
    if args.list_tools:
        print("Fetching available tools...")
        tools = fetch_tools(args.mcpo_url)
        print(f"\nFound {len(tools)} tools:\n")
        for tool in sorted(tools, key=lambda t: t["function"]["name"]):
            func = tool["function"]
            print(f"{Colors.BOLD}{func['name']}{Colors.RESET}")
            print(f"  {func['description']}")
            if func['parameters'].get('properties'):
                print(f"  Parameters: {', '.join(func['parameters']['properties'].keys())}")
            print()
        return

    # Use model from args (either default or explicitly specified)
    model = args.model

    # One-off query mode
    if args.query:
        # Load tools silently
        tools = fetch_tools(args.mcpo_url)

        # Execute single query with system message
        messages = [
            {
                "role": "system",
                "content": """You are a helpful assistant with access to tools. When the user asks questions that can be answered using the available tools, you MUST use them instead of providing manual instructions.

Guidelines:
- For systemd logs or journal queries: Use journal_logs_tail or journal_logs_query tools
- For file operations: Use filesystem tools
- For NixOS packages: Use mcp-nixos tools
- NEVER tell users to run journalctl, cat, or other commands manually when you have tools available
- Always use the appropriate tool for the task"""
            },
            {"role": "user", "content": args.query}
        ]

        try:
            response = requests.post(
                f"{args.ollama_url}/api/chat",
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
            tool_calls = assistant_message.get("tool_calls", [])

            # Handle JSON tool calls in content
            if not tool_calls:
                content = assistant_message.get("content", "").strip()
                if content.startswith("{") and ("name" in content or "function" in content):
                    try:
                        parsed = json.loads(content)
                        if "name" in parsed and "arguments" in parsed:
                            tool_calls = [{
                                "function": {
                                    "name": parsed["name"],
                                    "arguments": parsed.get("arguments", {})
                                }
                            }]
                    except json.JSONDecodeError:
                        pass

            # Execute tool calls if any
            if tool_calls:
                for tool_call in tool_calls:
                    function = tool_call.get("function", {})
                    tool_name = function.get("name", "")
                    arguments = function.get("arguments", {})

                    parts = tool_name.split("_", 1)
                    if len(parts) >= 2:
                        server = parts[0]
                        endpoint = "_".join(parts[1:]).replace("_", ".")
                        tool_result = call_tool(server, endpoint, arguments, args.mcpo_url)
                        messages.append({"role": "tool", "content": tool_result})

                # Get final response
                response = requests.post(
                    f"{args.ollama_url}/api/chat",
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

            # Print only the final response
            content = assistant_message.get("content", "")
            if content:
                print(content)
            else:
                print("No response received")

        except requests.exceptions.RequestException as e:
            print(f"Error: {str(e)}", file=sys.stderr)
            sys.exit(1)
        except Exception as e:
            print(f"Unexpected error: {str(e)}", file=sys.stderr)
            sys.exit(1)

        return

    try:
        chat(model, args.ollama_url, args.mcpo_url)
    except KeyboardInterrupt:
        print("\nInterrupted by user")
        sys.exit(0)


if __name__ == "__main__":
    main()
