{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.services.buzz-relay;
in
{
  options.services.buzz-relay = {
    enable = lib.mkEnableOption "Buzz relay server";

    package = lib.mkPackageOption pkgs "buzz-relay" { };

    databaseUrl = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "PostgreSQL connection URL (DATABASE_URL). Required for production.";
    };

    redisUrl = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Redis connection URL (REDIS_URL). Defaults to redis://localhost:6379 if unset.";
    };

    relayUrl = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Public WebSocket URL advertised in NIP-11 (RELAY_URL). Required if autoMigrate or requireRelayMembership is true.";
    };

    bindAddr = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Address to bind the HTTP/WebSocket server to (BUZZ_BIND_ADDR). Defaults to 0.0.0.0:3000.";
    };

    healthPort = lib.mkOption {
      type = lib.types.port;
      default = 8080;
      description = "TCP port for health probes (/health).";
    };

    metricsPort = lib.mkOption {
      type = lib.types.port;
      default = 9102;
      description = "TCP port for Prometheus metrics (/metrics).";
    };

    requireAuthToken = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Require authentication tokens for REST API access. Must be true for production.";
    };

    autoMigrate = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Run database migrations on startup (BUZZ_AUTO_MIGRATE).";
    };

    relayPrivateKeyFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Path to a file containing the relay's hex-encoded private key (BUZZ_RELAY_PRIVATE_KEY). Required when requireAuthToken is true.";
      example = "/run/secrets/buzz-relay-key";
    };

    environment = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      description = "Additional environment variables passed to the relay. Overrides any defaults.";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.buzz-relay = {
      description = "Buzz WebSocket relay server";
      wantedBy = [ "multi-user.target" ];
      after =
        [ "network.target" ]
        ++ lib.optional (cfg.databaseUrl != null) "postgresql.service"
        ++ lib.optional (cfg.redisUrl != null) "redis.service";

      serviceConfig = {
        Type = "simple";
        ExecStart = "${cfg.package}/bin/buzz-relay";
        Restart = "always";
        RestartSec = "5";
        TimeoutStartSec = "30";
        DynamicUser = true;
        StateDirectory = "buzz-relay";
      } // lib.optionalAttrs (cfg.relayPrivateKeyFile != null) {
        EnvironmentFile = cfg.relayPrivateKeyFile;
      };

      environment =
        {
          BUZZ_BIND_ADDR = lib.mkDefault (cfg.bindAddr);
          BUZZ_HEALTH_PORT = toString cfg.healthPort;
          BUZZ_METRICS_PORT = toString cfg.metricsPort;
          BUZZ_REQUIRE_AUTH_TOKEN = if cfg.requireAuthToken then "true" else "false";
          BUZZ_AUTO_MIGRATE = if cfg.autoMigrate then "true" else "false";
          BUZZ_GIT_REPO_PATH = "/var/lib/buzz-relay/repos";
        }
        // lib.optionalAttrs (cfg.databaseUrl != null) { DATABASE_URL = cfg.databaseUrl; }
        // lib.optionalAttrs (cfg.redisUrl != null) { REDIS_URL = cfg.redisUrl; }
        // lib.optionalAttrs (cfg.relayUrl != null) { RELAY_URL = cfg.relayUrl; }
        // cfg.environment;
    };
  };
}
