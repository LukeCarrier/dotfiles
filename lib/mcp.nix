{lib}:
{
  substitute = config: lib: text:
    let
      refs = builtins.match "(@[^@]+@)" text;
    in
    if refs == null then text else
      let
        keys = map (p: lib.removePrefix "@" (lib.removeSuffix "@" p)) refs;
        replacements = map (key: config.sops.placeholder.${key}) keys;
      in
      builtins.replaceStrings refs replacements text;
}
