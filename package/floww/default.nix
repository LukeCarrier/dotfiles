{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "floww";
  version = "0.5.1";

  src = fetchFromGitHub {
    owner = "dagimg-dot";
    repo = "floww";
    rev = "v${version}";
    hash = "sha256-yC9hMeDDJsn8U3mmlUVgfpvmY+5QETL4drY7trXwwmU=";
  };

  vendorHash = "sha256-b9hcN6MPLa5NzuByAk2/MiuVdb5r3Gyt++xZ5ceOEcg=";

  ldflags = [
    "-s"
    "-w"
    "-X main.version=${version}"
  ];

  subPackages = [ "cmd/floww" ];

  meta = with lib; {
    description = "Workflow management for Linux desktops";
    homepage = "https://github.com/dagimg-dot/floww";
    license = licenses.mit;
    platforms = platforms.linux;
    mainProgram = "floww";
  };
}
