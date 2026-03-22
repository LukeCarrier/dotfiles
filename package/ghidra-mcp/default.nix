{
  lib,
  python3Packages,
  fetchFromGitHub,
  makeWrapper,
  callPackage,
}:

let
  # Build the Ghidra plugin separately
  plugin = callPackage ./plugin.nix { };
in

python3Packages.buildPythonApplication rec {
  pname = "ghidra-mcp";
  version = "4.3.0";
  pyproject = false;

  src = fetchFromGitHub {
    owner = "bethington";
    repo = "ghidra-mcp";
    rev = "v${version}";
    hash = "sha256-+37kC6Iji0Vb3NMVNdxsPbZMd6AWUX5vNqru9yooUvs=";
  };

  nativeBuildInputs = [ makeWrapper ];

  propagatedBuildInputs = with python3Packages; [
    mcp
    requests
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin $out/lib/${pname}

    # Install the Python bridge
    cp bridge_mcp_ghidra.py $out/lib/${pname}/

    # Install helper scripts if present
    [ -d ghidra_scripts ] && cp -r ghidra_scripts $out/lib/${pname}/ || true
    [ -d docs ] && mkdir -p $out/share/doc/${pname} && cp -r docs $out/share/doc/${pname}/ || true

    # Create the main executable
    makeWrapper ${python3Packages.python.interpreter} $out/bin/ghidra-mcp-bridge \
      --add-flags "$out/lib/${pname}/bridge_mcp_ghidra.py" \
      --prefix PYTHONPATH : "$out/lib/${pname}:$PYTHONPATH"

    runHook postInstall
  '';

  # Note: The Ghidra plugin (Java component) is not built by this package.
  # Users need to build and install the plugin separately using Maven and Ghidra.
  # This package provides the Python MCP bridge that communicates with the plugin.

  passthru = {
    inherit src plugin;
    # Expose the plugin for easy installation
    ghidraPlugin = plugin;
  };

  meta = with lib; {
    description = "MCP bridge for Ghidra reverse engineering platform";
    longDescription = ''
      Complete ghidra-mcp package including both the Python MCP bridge and
      the Ghidra plugin (built for Ghidra ${plugin.ghidra.version}).

      Architecture:
      - Ghidra plugin (Java) runs HTTP server inside Ghidra on localhost:8089
        Access via: ghidra-mcp.ghidraPlugin
      - Python bridge translates MCP protocol to HTTP requests
        Access via: ghidra-mcp (this package)

      The bridge does NOT launch Ghidra - it expects Ghidra to be running
      with the plugin loaded and HTTP server started.

      Features:
      - 193 MCP tools for comprehensive binary analysis
      - Battle-tested AI workflows for function documentation
      - Cross-binary documentation transfer with function hashing
      - Support for both GUI and headless Ghidra modes

      Installation:
      1. Install plugin: See ghidra-mcp-plugin-info for instructions
      2. Start Ghidra and enable plugin via Tools > GhidraMCP > Start MCP Server
      3. Run: ghidra-mcp-bridge
    '';
    homepage = "https://github.com/bethington/ghidra-mcp";
    license = licenses.asl20;
    maintainers = [ ];
    mainProgram = "ghidra-mcp-bridge";
  };
}
