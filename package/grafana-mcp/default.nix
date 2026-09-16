{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "mcp-grafana";
  version = "1.4.2";

  src = fetchFromGitHub {
    owner = "grafana";
    repo = "mcp-grafana";
    rev = "v${version}";
    hash = "sha256-MUqVsrfjlDLanWzXzMVGYhlXjF23ovGm/ocz7A4vrxw=";
  };

  vendorHash = "sha256-y/Hk1hDQ00wHqTOcaoKVvz2PgF0ZiwHartbuF7qEkXc=";

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
