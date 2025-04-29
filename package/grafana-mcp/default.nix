{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "mcp-grafana";
  version = "0.11.2";

  src = fetchFromGitHub {
    owner = "grafana";
    repo = "mcp-grafana";
    rev = "v${version}";
    hash = "sha256-HqNKbpmZCrEST2wesUo/swkT5wcnV2ZOpwYmqq+2EzA=";
  };

  vendorHash = "sha256-w4v1/RqnNfGFzapmWd96UTT4Sc18lSVX5HvsXWWmhSY=";

  ldflags = [
    "-s"
    "-w"
    "-X main.version=${version}"
  ];

  subPackages = [ "cmd/mcp-grafana" ];

  meta = with lib; {
    description = "Model Context Protocol (MCP) server for Grafana";
    homepage = "https://github.com/grafana/mcp-grafana";
    license = licenses.asl20;
    maintainers = [ ];
    mainProgram = "mcp-grafana";
  };
}
