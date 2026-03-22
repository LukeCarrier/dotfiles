{ pkgs, ... }:
let
  # Python with tkinter support for PyGhidra GUI
  python-with-tkinter = pkgs.python3.withPackages (ps: [ ps.tkinter ]);

  ghidra-with-python = pkgs.symlinkJoin {
    name = "${pkgs.ghidra.pname}-with-python-${pkgs.ghidra.version}";
    paths = [ pkgs.ghidra ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      # Wrap all Ghidra shell scripts with Python (with tkinter) and Java in PATH
      wrapProgram "$out/lib/ghidra/ghidraRun" \
        --prefix PATH : ${pkgs.lib.makeBinPath [ python-with-tkinter pkgs.jdk21 ]}
      
      for script in "$out/lib/ghidra/support"/*; do
        if [ -f "$script" ] && head -1 "$script" | grep -q "^#!.*bash"; then
          wrapProgram "$script" \
            --prefix PATH : ${pkgs.lib.makeBinPath [ python-with-tkinter pkgs.jdk21 ]}
        fi
      done

      # Create a convenient launcher for PyGhidra that auto-supplies the install directory
      makeWrapper "$out/bin/ghidra-pyghidraRun" "$out/bin/ghidra-pyghidra" \
        --add-flags "$out/lib/ghidra"
    '';
  };

  ghidra-mcp-plugin = pkgs.ghidra-mcp-plugin;
  ghidraExtensionsDir = ".ghidra/.ghidra_${pkgs.ghidra.version}_PUBLIC/Extensions";
in
{
  home.file."${ghidraExtensionsDir}/GhidraMCP-${ghidra-mcp-plugin.version}.zip".source =
    "${ghidra-mcp-plugin}/lib/ghidra/Extensions/GhidraMCP-${ghidra-mcp-plugin.version}.zip";

  home.packages = [
    ghidra-with-python
    ghidra-mcp-plugin
  ];
}
