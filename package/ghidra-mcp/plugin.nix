{
  lib,
  stdenv,
  fetchFromGitHub,
  maven,
  jdk21,
  makeWrapper,
  ghidra,
}:

stdenv.mkDerivation rec {
  pname = "ghidra-mcp-plugin";
  version = "4.3.0";

  src = fetchFromGitHub {
    owner = "bethington";
    repo = "ghidra-mcp";
    rev = "v${version}";
    hash = "sha256-+37kC6Iji0Vb3NMVNdxsPbZMd6AWUX5vNqru9yooUvs=";
  };

  nativeBuildInputs = [
    maven
    jdk21
    makeWrapper
  ];

  buildInputs = [ ghidra ];

  # Configure Maven to use Ghidra JARs from the Nix store
  postPatch = ''
    # Update pom.xml to match the Ghidra version from nixpkgs
    substituteInPlace pom.xml \
      --replace-fail '<ghidra.version>12.0.3</ghidra.version>' \
                     '<ghidra.version>${ghidra.version}</ghidra.version>'
  '';

  buildPhase = ''
    runHook preBuild

    # Point to Ghidra installation for JARs
    export GHIDRA_INSTALL_DIR=${ghidra}/lib/ghidra

    # Create a local Maven repository and install Ghidra JARs
    mkdir -p .m2/repository
    export MAVEN_OPTS="-Dmaven.repo.local=$PWD/.m2/repository"

    # Install required Ghidra JARs into local Maven repo
    for jar in \
      Generic \
      SoftwareModeling \
      Project \
      Docking \
      Decompiler \
      Utility \
      Base \
      Gui \
      FileSystem \
      Help \
      DB \
      Graph \
      Emulation \
      PDB \
      FunctionID; do
      
      # Find the JAR in Ghidra installation
      jarPath=$(find $GHIDRA_INSTALL_DIR/Ghidra -name "$jar.jar" | head -1)
      
      if [ -n "$jarPath" ]; then
        echo "Installing $jar.jar from $jarPath"
        mvn install:install-file \
          -Dfile="$jarPath" \
          -DgroupId=ghidra \
          -DartifactId=$jar \
          -Dversion=${ghidra.version} \
          -Dpackaging=jar \
          -DlocalRepositoryPath=$PWD/.m2/repository
      else
        echo "Warning: Could not find $jar.jar"
      fi
    done

    # Build the plugin
    mvn clean package assembly:single -DskipTests \
      -Dmaven.repo.local=$PWD/.m2/repository

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/ghidra/Extensions

    # Install the extension ZIP
    if [ -f target/GhidraMCP-${version}.zip ]; then
      cp target/GhidraMCP-${version}.zip $out/lib/ghidra/Extensions/
    else
      echo "Error: Extension ZIP not found"
      exit 1
    fi

    # Also extract it for convenience
    mkdir -p $out/share/ghidra-mcp-plugin
    cd $out/share/ghidra-mcp-plugin
    ${jdk21}/bin/jar xf $out/lib/ghidra/Extensions/GhidraMCP-${version}.zip

    # Create a helper script to show installation instructions
    mkdir -p $out/bin
    cat > $out/bin/ghidra-mcp-plugin-info <<'EOF'
#!/bin/sh
echo "GhidraMCP Plugin v${version}"
echo ""
echo "Extension location: $out/lib/ghidra/Extensions/GhidraMCP-${version}.zip"
echo ""
echo "To install in Ghidra:"
echo "  1. Open Ghidra"
echo "  2. Go to File > Install Extensions"
echo "  3. Click the '+' button"
echo "  4. Navigate to: $out/lib/ghidra/Extensions/GhidraMCP-${version}.zip"
echo "  5. Restart Ghidra"
echo "  6. Enable via: File > Configure > Configure All Plugins > GhidraMCP"
echo ""
echo "Or copy to your Ghidra extensions directory:"
echo "  mkdir -p ~/.ghidra/.ghidra_${ghidra.version}_PUBLIC/Extensions"
echo "  cp $out/lib/ghidra/Extensions/GhidraMCP-${version}.zip ~/.ghidra/.ghidra_${ghidra.version}_PUBLIC/Extensions/"
EOF
    chmod +x $out/bin/ghidra-mcp-plugin-info

    runHook postInstall
  '';

  passthru = {
    inherit ghidra;
    extensionPath = "${placeholder "out"}/lib/ghidra/Extensions/GhidraMCP-${version}.zip";
  };

  meta = with lib; {
    description = "Ghidra plugin for ghidra-mcp (Java component)";
    longDescription = ''
      The Java Ghidra plugin component of ghidra-mcp. This plugin runs inside
      Ghidra and provides an HTTP server that exposes Ghidra's reverse engineering
      capabilities.

      After installing this package, you need to install the extension into Ghidra:
      - Run 'ghidra-mcp-plugin-info' for installation instructions
      - Or manually install via Ghidra's File > Install Extensions menu

      Built for Ghidra ${ghidra.version}.
    '';
    homepage = "https://github.com/bethington/ghidra-mcp";
    license = licenses.asl20;
    maintainers = [ ];
    platforms = platforms.unix;
    mainProgram = "ghidra-mcp-plugin-info";
  };
}
