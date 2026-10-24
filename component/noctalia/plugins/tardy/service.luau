--!nonstrict
-- Owns the single Tardy daemon and republishes its waybar-format status lines.
--
-- `runStream` has no exit callback, so the shell loop restarts the daemon if it
-- dies. The loop is stopped by the host when the plugin is disabled or reloaded.

local function publish(line)
  local status = noctalia.json.decode(line)
  if type(status) ~= "table" then
    return
  end

  noctalia.state.set("tardy", {
    text = status.text or "",
    class = status.class or "empty",
    tooltip = status.tooltip or "",
  })
end

if not noctalia.commandExists("tardy") then
  noctalia.log("tardy: command not found in PATH")
  return
end

local command = "while :; do tardy daemon --format=waybar; sleep 5; done"

if not noctalia.runStream(command, publish) then
  noctalia.log("tardy: failed to start `tardy daemon --format=waybar`")
end
