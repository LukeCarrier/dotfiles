{
  flake,
  hostname,
  user,
}:
let
  configuration = flake.nixosConfigurations.${hostname}.extendModules {
    modules = [ ./module.nix ];
    specialArgs = {
      vmHomeActivation = flake.homeConfigurations."${user}@${hostname}".activationPackage;
      vmHomeUser = user;
    };
  };
in
configuration.config.system.build.vm
