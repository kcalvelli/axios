#!/usr/bin/env python3
"""
A simple, streaming, and tool-aware CLI for chatting with Ollama models via mcpo.
Usage: mcp-chat [--model MODEL] [--mcpo-url URL] [--query "Your query"]
"""

import argparse
import json
import sys
import requests
from typing import List, Dict, Any, Generator

# --- Configuration ---
DEFAULT_MODEL = "qwen2.5-coder:7b"
DEFAULT_OLLAMA_URL = "http://localhost:11434"
DEFAULT_MCPO_URL = "http://localhost:8000"
REQUEST_TIMEOUT = 120

# --- ANSI Color Codes ---
class Colors:
    USER = "\033[94m"
    ASSISTANT = "\033[92m"
    TOOL = "\033[93m"
    ERROR = "\033[91m"
    RESET = "\033[0m"
    BOLD = "\033[1m"

# --- Chat Client Class ---
class ChatClient:
    """Manages the chat session, including tools, messages, and API interaction."""

    def __init__(self, model: str, ollama_url: str, mcpo_url: str):
        self.model = model
        self.ollama_url = ollama_url
        self.mcpo_url = mcpo_url
        self.tools: List[Dict[str, Any]] = []
        self.messages: List[Dict[str, Any]] = [
            {
                "role": "system",
                "content": """You are a helpful assistant with access to tools. When the user asks questions that can be answered using the available tools, you MUST use them instead of providing manual instructions.

Guidelines:
- For systemd logs or journal queries: Use journal tools.
- For file operations: Use filesystem tools.
- For NixOS packages: Use mcp-nixos tools.
- NEVER tell users to run journalctl, cat, or other commands manually when you have tools available.
- Always use the appropriate tool for the task.
- Use `.` as the separator for tool names, e.g., `filesystem.read_file`.
"""
            }
        ]

    def load_tools(self, silent: bool = False):
        """Fetch tool definitions from all MCP servers via mcpo."""
        if not silent:
            print("Loading tools...", end="", flush=True)

        try:
            # Dynamic server discovery
            resp = requests.get(self.mcpo_url, timeout=5)
            resp.raise_for_status()
            server_names = resp.json().get("servers", [])
        except (requests.RequestException, json.JSONDecodeError) as e:
            if not silent:
                print(f"{Colors.ERROR}\nWarning: Failed to discover servers from mcpo root. Falling back to default list. ({e}){Colors.RESET}", file=sys.stderr)
            server_names = ["journal", "mcp-nixos", "sequential-thinking", "context7", "filesystem"]

        for server in server_names:
            try:
                resp = requests.get(f"{self.mcpo_url}/{server}/openapi.json", timeout=5)
                if resp.status_code == 200:
                    self._parse_and_add_tools(server, resp.json())
            except requests.RequestException as e:
                if not silent:
                    print(f"{Colors.ERROR}\nWarning: Failed to fetch tools from {server}: {e}{Colors.RESET}", file=sys.stderr)

        if not silent:
            print(f" {len(self.tools)} tools loaded.\n")

    def _parse_and_add_tools(self, server_name: str, openapi_spec: Dict[str, Any]):
        """Parse an OpenAPI spec and add the defined tools."""
        server_info = openapi_spec.get("info", {})
        server_title = server_info.get("title", server_name)

        for path, methods in openapi_spec.get("paths", {}).items():
            for method, details in methods.items():
                if method.lower() != "post":
                    continue

                endpoint = path.strip('/')
                tool_name = f"{server_name}.{endpoint.replace('/', '_')}"

                schema_ref = details.get("requestBody", {}).get("content", {}).get("application/json", {}).get("schema", {})
                if "$ref" in schema_ref:
                    ref_path = schema_ref["$ref"].split('/')[1:]
                    schema_obj = openapi_spec
                    for part in ref_path:
                        schema_obj = schema_obj.get(part, {})
                    schema_ref = schema_obj

                description = details.get("description") or details.get("summary", "No description.")
                
                self.tools.append({
                    "type": "function",
                    "function": {
                        "name": tool_name,
                        "description": f"[{server_title}] {description}",
                        "parameters": {
                            "type": "object",
                            "properties": schema_ref.get("properties", {}),
                            "required": schema_ref.get("required", [])
                        }
                    }
                })

    def _call_tool(self, tool_name: str, arguments: Dict[str, Any]) -> str:
        """Execute a tool call via mcpo."""
        print(f"{Colors.TOOL}[Tool Call: {tool_name}]{Colors.RESET}")
        print(f"{Colors.TOOL}[Arguments: {json.dumps(arguments, indent=2)}]{Colors.RESET}")

        parts = tool_name.split('.', 1)
        if len(parts) != 2:
            return f"Error: Invalid tool name format '{tool_name}'. Expected 'server.endpoint'."
        
        server, endpoint = parts
        url = f"{self.mcpo_url}/{server}/{endpoint.replace('_', '/')}"

        try:
            resp = requests.post(url, json=arguments, timeout=30)
            resp.raise_for_status()
            result = resp.json()
            return json.dumps(result, indent=2)
        except requests.RequestException as e:
            return f"Error calling tool {tool_name}: {e}"

    def _handle_tool_calls(self, tool_calls: List[Dict[str, Any]]):
        """Process tool calls from the model and append results."""
        for tool_call in tool_calls:
            function = tool_call.get("function", {})
            tool_name = function.get("name", "")
            arguments = function.get("arguments", {})
            
            tool_result = self._call_tool(tool_name, arguments)
            print(f"{Colors.TOOL}[Tool Result]{Colors.RESET}\n{tool_result}\n")
            
            self.messages.append({"role": "tool", "content": tool_result})

    def send_request(self, stream: bool = True) -> Generator[str, None, None]:
        """Send chat request to Ollama and handle the response."""
        try:
            response = requests.post(
                f"{self.ollama_url}/api/chat",
                json={"model": self.model, "messages": self.messages, "tools": self.tools, "stream": stream},
                timeout=REQUEST_TIMEOUT,
                stream=stream
            )
            response.raise_for_status()

            if stream:
                buffer = ""
                for chunk in response.iter_content(chunk_size=None):
                    buffer += chunk.decode('utf-8')
                    while '\n' in buffer:
                        line, buffer = buffer.split('\n', 1)
                        if line:
                            part = json.loads(line)
                            self.messages.append(part['message'])
                            content = part.get("message", {}).get("content", "")
                            if content:
                                yield content
                            
                            if part.get("done"):
                                tool_calls = part.get("message", {}).get("tool_calls")
                                if tool_calls:
                                    self._handle_tool_calls(tool_calls)
                                    # After tool calls, get the final, non-streamed response
                                    final_gen = self.send_request(stream=True)
                                    for final_content in final_gen:
                                        yield final_content
                                return
            else: # Non-streaming for single query
                result = response.json()
                assistant_message = result.get("message", {})
                self.messages.append(assistant_message)
                
                if tool_calls := assistant_message.get("tool_calls"):
                    self._handle_tool_calls(tool_calls)
                    # Get final response after tool execution
                    final_result = requests.post(
                        f"{self.ollama_url}/api/chat",
                        json={"model": self.model, "messages": self.messages, "stream": False},
                        timeout=REQUEST_TIMEOUT
                    ).json()
                    final_message = final_result.get("message", {})
                    self.messages.append(final_message)
                    yield final_message.get("content", "")
                else:
                    yield assistant_message.get("content", "")

        except requests.RequestException as e:
            yield f"{Colors.ERROR}Error: {e}{Colors.RESET}\n"
        except json.JSONDecodeError:
            yield f"{Colors.ERROR}Error: Failed to decode API response.{Colors.RESET}\n"

    def chat_loop(self):
        """The main interactive chat loop."""
        print(f"{Colors.BOLD}MCP Chat{Colors.RESET} - Model: {self.model}")
        self.load_tools()

        while True:
            try:
                user_input = input(f"{Colors.USER}You:{Colors.RESET} ").strip()
                if user_input.lower() in ["exit", "quit"]:
                    print("Goodbye!")
                    break
                if not user_input:
                    continue

                self.messages.append({"role": "user", "content": user_input})
                
                print(f"{Colors.ASSISTANT}Assistant:{Colors.RESET} ", end="", flush=True)
                for content_part in self.send_request(stream=True):
                    print(content_part, end="", flush=True)
                print("\n")

            except (EOFError, KeyboardInterrupt):
                print("\nGoodbye!")
                break

    def single_query(self, query: str):
        """Handle a single, non-interactive query."""
        self.load_tools(silent=True)
        self.messages.append({"role": "user", "content": query})
        
        full_response = "".join(self.send_request(stream=False))
        print(full_response)

# --- Main Execution ---
def main():
    parser = argparse.ArgumentParser(description="Chat with Ollama using MCP tools.")
    parser.add_argument("--model", default=DEFAULT_MODEL, help=f"Ollama model (default: {DEFAULT_MODEL})")
    parser.add_argument("--ollama-url", default=DEFAULT_OLLAMA_URL, help=f"Ollama API URL (default: {DEFAULT_OLLAMA_URL})")
    parser.add_argument("--mcpo-url", default=DEFAULT_MCPO_URL, help=f"MCPO URL (default: {DEFAULT_MCPO_URL})")
    parser.add_argument("--list-tools", action="store_true", help="List available tools and exit.")
    parser.add_argument("-q", "--query", type=str, help="Execute a single query and exit.")
    args = parser.parse_args()

    client = ChatClient(args.model, args.ollama_url, args.mcpo_url)

    if args.list_tools:
        client.load_tools()
        print(f"\nFound {len(client.tools)} tools:\n")
        for tool in sorted(client.tools, key=lambda t: t["function"]["name"]):
            func = tool["function"]
            print(f"{Colors.BOLD}{func['name']}{Colors.RESET}")
            print(f"  {func['description']}")
            if func['parameters'].get('properties'):
                print(f"  Parameters: {', '.join(func['parameters']['properties'].keys())}")
            print()
        return

    if args.query:
        client.single_query(args.query)
    else:
        client.chat_loop()

if __name__ == "__main__":
    main()