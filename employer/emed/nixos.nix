{ config, lib, pkgs, ... }:
{
  nixpkgs.overlays = lib.mkAfter [
    (final: prev: {
      falcon-sensor-unwrapped = prev.stdenv.mkDerivation {
        pname = "falcon-sensor-unwrapped";
        version = "7.36.0-18909";
        src = prev.fetchurl {
          name = "falcon-sensor_7.36.0-18909_amd64.deb";
          url = "https://attic.emed.com/falcon-sensor_7.36.0-18909_amd64.deb";
          hash = "sha256-D70fSI5Ms2qN8+BVyjYtK75IgT8QeiDqCt95+lqBvP0=";
        };
        nativeBuildInputs = with prev; [ autoPatchelfHook dpkg zlib ];
        propagatedBuildInputs = with prev; [ openssl libnl ];
        sourceRoot = ".";
        unpackCmd = ''dpkg-deb -x "$src" .'';
        installPhase = ''cp -r ./ $out/'';
        meta = with prev.lib; {
          mainProgram = "falconctl";
          description = "Crowdstrike Falcon Sensor";
          homepage = "https://www.crowdstrike.com/";
          license = licenses.unfree;
          platforms = platforms.linux;
        };
      };
      cyberhaven-unwrapped = prev.stdenv.mkDerivation {
        pname = "cyberhaven-unwrapped";
        version = "26.03.03.141-ef2a88";
        src = prev.fetchurl {
          name = "Cyberhaven-26.03.03.141-ef2a88.deb";
          url = "https://attic.emed.com/Cyberhaven-26.03.03.141-ef2a88.deb";
          hash = "sha256-QP2OIKYI03nclno85kFXwZRuB/KaIoMtN9RTXxpt45w=";
        };
        nativeBuildInputs = with prev; [ autoPatchelfHook dpkg ];
        buildInputs = with prev; [
          atk bzip2 cairo gdk-pixbuf glib gtk3 keyutils.lib libgcc.lib libnl
          libx11 libxau openssl pango util-linux.lib xz zlib zstd
        ];
        sourceRoot = ".";
        unpackCmd = ''dpkg-deb -x "$src" .'';
        installPhase = ''
          cp -r ./ $out/
          rm -f $out/opt/cyberhaven/lib/libcyberhavennet-legacy.so
        '';
        meta = with prev.lib; {
          description = "Cyberhaven endpoint security agent";
          homepage = "https://www.cyberhaven.com/";
          license = licenses.unfree;
          platforms = platforms.linux;
        };
      };
    })
  ];

  sops.secrets = {
    "cyberhaven/backend" = {};
    "cyberhaven/installToken" = {};
    "falcon-sensor/cid" = {};
  };

  services = {
    cyberhaven = {
      enable = true;
      backendFile = config.sops.secrets."cyberhaven/backend".path;
      installTokenFile = config.sops.secrets."cyberhaven/installToken".path;
    };
    falcon-sensor = {
      enable = true;
      cidFile = config.sops.secrets."falcon-sensor/cid".path;
      kernelPackages = null;
    };
  };
}
