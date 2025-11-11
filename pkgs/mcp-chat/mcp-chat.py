#!/usr/bin/env python3
"""
A simple, streaming, and tool-aware CLI for chatting with Ollama models via mcpo.
Usage: mcp-chat [--model MODEL] [--mcpo-url URL] [--query "Your query"]
"""

import argparse
import json
import re
import sys
import requests
from typing import List, Dict, Any, Generator, Tuple
import numpy as np

# --- Configuration ---
DEFAULT_MODEL = "llama3.1:8b"
DEFAULT_EMBEDDING_MODEL = "nomic-embed-text"
DEFAULT_OLLAMA_URL = "http://localhost:11434"
DEFAULT_MCPO_URL = "http://localhost:8000"
DEFAULT_TOP_K_TOOLS = 15
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

    def __init__(self, model: str, ollama_url: str, mcpo_url: str, embedding_model: str, top_k_tools: int):
        self.model = model
        self.ollama_url = ollama_url
        self.mcpo_url = mcpo_url
        self.embedding_model = embedding_model
        self.top_k_tools = top_k_tools
        self.tools: List[Dict[str, Any]] = []
        self.tool_embeddings: List[np.ndarray] = []
        self.messages: List[Dict[str, Any]] = [
            {
                "role": "system",
                "content": """You are a helpful assistant. You have tools available - USE THEM. Do not suggest commands or manual steps. Call the appropriate tool to answer the question directly."""
            }
        ]

    def load_tools(self, silent: bool = False):
        """Fetch tool definitions from all MCP servers via mcpo."""
        if not silent:
            print("Loading tools...", end="", flush=True)

        try:
            # Dynamic server discovery from OpenAPI spec
            resp = requests.get(f"{self.mcpo_url}/openapi.json", timeout=5)
            resp.raise_for_status()
            openapi_spec = resp.json()

            # Parse server names from description field
            # Format: "- [server-name](/server-name/docs)"
            description = openapi_spec.get("info", {}).get("description", "")
            server_names = re.findall(r'\[([^\]]+)\]\(/[^\)]+/docs\)', description)

            if not server_names:
                raise ValueError("No servers found in OpenAPI description")
        except (requests.RequestException, json.JSONDecodeError, ValueError) as e:
            if not silent:
                print(f"{Colors.ERROR}\nWarning: Failed to discover servers from mcpo. Falling back to default list. ({e}){Colors.RESET}", file=sys.stderr)
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
            print(f" {len(self.tools)} tools loaded.")

        # Compute embeddings for all tools
        self._compute_tool_embeddings(silent)

        if not silent:
            print()

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

    def _get_embedding(self, text: str) -> np.ndarray:
        """Get embedding vector for text using Ollama."""
        try:
            resp = requests.post(
                f"{self.ollama_url}/api/embeddings",
                json={"model": self.embedding_model, "prompt": text},
                timeout=30
            )
            resp.raise_for_status()
            embedding = resp.json().get("embedding", [])
            return np.array(embedding)
        except requests.RequestException as e:
            print(f"{Colors.ERROR}Warning: Failed to get embedding: {e}{Colors.RESET}", file=sys.stderr)
            return np.zeros(768)  # Return zero vector on error

    def _compute_tool_embeddings(self, silent: bool = False):
        """Compute and store embeddings for all tools."""
        if not silent:
            print(" Computing embeddings...", end="", flush=True)

        for tool in self.tools:
            func = tool["function"]
            # Create a comprehensive text representation of the tool
            tool_text = f"{func['name']}: {func['description']}"
            if func['parameters'].get('properties'):
                param_names = ', '.join(func['parameters']['properties'].keys())
                tool_text += f" Parameters: {param_names}"

            embedding = self._get_embedding(tool_text)
            self.tool_embeddings.append(embedding)

        if not silent:
            print(f" Done.")

    def _cosine_similarity(self, a: np.ndarray, b: np.ndarray) -> float:
        """Calculate cosine similarity between two vectors."""
        if np.linalg.norm(a) == 0 or np.linalg.norm(b) == 0:
            return 0.0
        return np.dot(a, b) / (np.linalg.norm(a) * np.linalg.norm(b))

    def _get_keyword_tool_prefixes(self, query: str) -> List[str]:
        """Get tool prefixes that should be included based on query keywords."""
        query_lower = query.lower()

        # Keyword patterns mapped to tool prefixes
        keyword_patterns = {
            "journal": ["error", "log", "fail", "crash", "panic", "systemd", "service", "unit", "boot"],
            "filesystem": ["file", "directory", "folder", "path", "read", "write", "list", "create"],
            "mcp-nixos": ["nix", "package", "nixos", "nixpkgs", "derivation", "flake"],
            "context7": ["documentation", "docs", "library", "api", "reference"],
            "sequential-thinking": ["think", "reason", "analyze", "plan", "solve"],
        }

        matched_prefixes = set()
        for prefix, keywords in keyword_patterns.items():
            for keyword in keywords:
                if keyword in query_lower:
                    matched_prefixes.add(prefix)
                    break  # Only need one match per prefix

        return list(matched_prefixes)

    def _select_relevant_tools(self, query: str) -> List[Dict[str, Any]]:
        """Select the most relevant tools using hybrid keyword + RAG approach."""
        if not self.tool_embeddings:
            # Fallback to all tools if embeddings failed
            return self.tools

        # Step 1: Get keyword-matched tool prefixes
        keyword_prefixes = self._get_keyword_tool_prefixes(query)

        # Step 2: Add all tools matching keyword prefixes (guaranteed inclusion)
        guaranteed_indices = set()
        for i, tool in enumerate(self.tools):
            tool_name = tool["function"]["name"]
            if any(tool_name.startswith(prefix + ".") for prefix in keyword_prefixes):
                guaranteed_indices.add(i)

        # Step 3: Use RAG to select remaining tools to fill up to top_k
        query_embedding = self._get_embedding(query)

        # Calculate similarities for all tools
        similarities = [
            (i, self._cosine_similarity(query_embedding, tool_emb))
            for i, tool_emb in enumerate(self.tool_embeddings)
        ]

        # Sort by similarity (descending)
        similarities.sort(key=lambda x: x[1], reverse=True)

        # Add top RAG tools until we reach top_k (excluding already guaranteed tools)
        # Limit diversity: max 4 tools per prefix from RAG to prevent overwhelming one category
        selected_indices = list(guaranteed_indices)
        prefix_counts = {}

        for idx, _ in similarities:
            if idx not in guaranteed_indices:
                tool_name = self.tools[idx]["function"]["name"]
                prefix = tool_name.split(".")[0]

                # Skip if this prefix already has 4 tools from RAG (not counting guaranteed)
                if prefix_counts.get(prefix, 0) >= 4:
                    continue

                selected_indices.append(idx)
                prefix_counts[prefix] = prefix_counts.get(prefix, 0) + 1

                if len(selected_indices) >= self.top_k_tools:
                    break

        # Return the selected tools
        return [self.tools[i] for i in selected_indices]

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

    def send_request(self, stream: bool = True, tools: List[Dict[str, Any]] = None) -> Generator[str, None, None]:
        """Send chat request to Ollama and handle the response."""
        # Use provided tools or default to all tools
        active_tools = tools if tools is not None else self.tools

        try:
            response = requests.post(
                f"{self.ollama_url}/api/chat",
                json={"model": self.model, "messages": self.messages, "tools": active_tools, "stream": stream},
                timeout=REQUEST_TIMEOUT,
                stream=stream
            )
            response.raise_for_status()

            if stream:
                buffer = ""
                complete_message = None
                for chunk in response.iter_content(chunk_size=None):
                    buffer += chunk.decode('utf-8')
                    while '\n' in buffer:
                        line, buffer = buffer.split('\n', 1)
                        if line:
                            part = json.loads(line)
                            content = part.get("message", {}).get("content", "")
                            if content:
                                yield content

                            if part.get("done"):
                                complete_message = part['message']
                                tool_calls = part.get("message", {}).get("tool_calls")
                                if tool_calls:
                                    print()  # Add newline before tool output
                                    self.messages.append(complete_message)
                                    self._handle_tool_calls(tool_calls)
                                    # After tool calls, use non-streaming mode for final response
                                    # (streaming mode seems to have issues with post-tool synthesis)
                                    print(f"{Colors.ASSISTANT}Assistant:{Colors.RESET} ", end="", flush=True)
                                    final_gen = self.send_request(stream=False, tools=active_tools)
                                    for final_content in final_gen:
                                        print(final_content, end="", flush=True)
                                    print()
                                    return

                # Append the complete message only once
                if complete_message:
                    self.messages.append(complete_message)
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
                        json={"model": self.model, "messages": self.messages, "tools": active_tools, "stream": False},
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

                # Select relevant tools for this query
                relevant_tools = self._select_relevant_tools(user_input)
                keyword_prefixes = self._get_keyword_tool_prefixes(user_input)
                if keyword_prefixes:
                    print(f"{Colors.TOOL}[Using {len(relevant_tools)} tools: {', '.join(keyword_prefixes)} + RAG]{Colors.RESET}")
                else:
                    print(f"{Colors.TOOL}[Using {len(relevant_tools)} tools via RAG]{Colors.RESET}")

                print(f"{Colors.ASSISTANT}Assistant:{Colors.RESET} ", end="", flush=True)
                # Use non-streaming mode as streaming has issues with RAG-selected tools
                response = "".join(self.send_request(stream=False, tools=relevant_tools))
                print(response)
                print()

            except (EOFError, KeyboardInterrupt):
                print("\nGoodbye!")
                break

    def single_query(self, query: str):
        """Handle a single, non-interactive query."""
        self.load_tools(silent=True)
        self.messages.append({"role": "user", "content": query})

        # Select relevant tools for this query
        relevant_tools = self._select_relevant_tools(query)

        full_response = "".join(self.send_request(stream=False, tools=relevant_tools))
        print(full_response)

# --- Main Execution ---
def main():
    parser = argparse.ArgumentParser(description="Chat with Ollama using MCP tools with RAG-based tool selection.")
    parser.add_argument("--model", default=DEFAULT_MODEL, help=f"Ollama model (default: {DEFAULT_MODEL})")
    parser.add_argument("--embedding-model", default=DEFAULT_EMBEDDING_MODEL, help=f"Embedding model for RAG (default: {DEFAULT_EMBEDDING_MODEL})")
    parser.add_argument("--top-k", type=int, default=DEFAULT_TOP_K_TOOLS, help=f"Number of relevant tools to select (default: {DEFAULT_TOP_K_TOOLS})")
    parser.add_argument("--ollama-url", default=DEFAULT_OLLAMA_URL, help=f"Ollama API URL (default: {DEFAULT_OLLAMA_URL})")
    parser.add_argument("--mcpo-url", default=DEFAULT_MCPO_URL, help=f"MCPO URL (default: {DEFAULT_MCPO_URL})")
    parser.add_argument("--list-tools", action="store_true", help="List available tools and exit.")
    parser.add_argument("-q", "--query", type=str, help="Execute a single query and exit.")
    args = parser.parse_args()

    client = ChatClient(args.model, args.ollama_url, args.mcpo_url, args.embedding_model, args.top_k)

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