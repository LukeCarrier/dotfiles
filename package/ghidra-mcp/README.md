# ghidra-mcp

Production-grade Model Context Protocol (MCP) server for Ghidra reverse engineering platform.

## About

This package provides **both components** of ghidra-mcp:
- Python MCP bridge (main package)
- Ghidra plugin (available via `ghidra-mcp.ghidraPlugin`)

## Architecture

The ghidra-mcp system consists of two separate components:

1. **Ghidra Plugin (Java)** - HTTP server running inside Ghidra
   - Built automatically for Ghidra ${ghidra.version} from nixpkgs
   - Must be installed into Ghidra and started manually via GUI
   - Exposes Ghidra's analysis capabilities via HTTP on `localhost:8089`
   - Available as: `pkgs.ghidra-mcp.ghidraPlugin`

2. **Python MCP Bridge** - Standalone MCP server
   - Connects to the Ghidra plugin's HTTP server
   - Translates MCP protocol to HTTP requests
   - Does NOT launch Ghidra automatically
   - Expects Ghidra to already be running with plugin loaded
   - Available as: `pkgs.ghidra-mcp`

## Features

- 193 MCP tools for comprehensive binary analysis
- Battle-tested AI workflows for function documentation
- Cross-binary documentation transfer with function hashing
- Support for both GUI and headless Ghidra modes

## Quick Start

### Step 1: Install the Ghidra Plugin

First, install the plugin into Ghidra:

```bash
# Get installation instructions
nix-shell -p '(import <nixpkgs> {}).callPackage ./package/ghidra-mcp {}.ghidraPlugin' \
  --run ghidra-mcp-plugin-info

# Or install directly to your Ghidra extensions directory
mkdir -p ~/.ghidra/.ghidra_12.0.2_PUBLIC/Extensions
cp $(nix-build '<nixpkgs>' -A ghidra-mcp.ghidraPlugin --no-out-link)/lib/ghidra/Extensions/GhidraMCP-4.3.0.zip \
   ~/.ghidra/.ghidra_12.0.2_PUBLIC/Extensions/
```

### Step 2: Start Ghidra with the Plugin

Start Ghidra and enable the plugin:

1. Open Ghidra and start a CodeBrowser window
2. Restart Ghidra if you just installed the extension
3. Enable the plugin: **File > Configure > Configure All Plugins > GhidraMCP**
4. Start the HTTP server: **Tools > GhidraMCP > Start MCP Server**
5. Verify it's running: `curl http://127.0.0.1:8089/check_connection`

### Step 3: Run the MCP Bridge

Now you can start the MCP bridge:

```bash
# Run with stdio transport (recommended for AI tools like Claude)
ghidra-mcp-bridge

# Run with SSE transport (for web/HTTP clients)
ghidra-mcp-bridge --transport sse --mcp-host 127.0.0.1 --mcp-port 8081

# Connect to Ghidra on a different port
ghidra-mcp-bridge --ghidra-server http://127.0.0.1:9000
```

The bridge will connect to the Ghidra HTTP server and expose 193 MCP tools for binary analysis.

## Using in NixOS/home-manager

Add to your configuration:

```nix
{
  environment.systemPackages = with pkgs; [
    ghidra
    ghidra-mcp
  ];
}
```

Or for home-manager:

```nix
{
  home.packages = with pkgs; [
    ghidra
    ghidra-mcp
  ];
}
```

The plugin is automatically built for the version of Ghidra in nixpkgs (currently 12.0.2).

## Documentation

- [GitHub Repository](https://github.com/bethington/ghidra-mcp)
- [Full Documentation](https://github.com/bethington/ghidra-mcp/tree/main/docs)
- [AI Workflow Prompts](https://github.com/bethington/ghidra-mcp/tree/main/docs/prompts)

## License

Apache License 2.0
