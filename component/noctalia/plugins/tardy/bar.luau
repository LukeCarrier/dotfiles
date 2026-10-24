--!nonstrict
-- Thin bar client of the `tardy` state published by service.luau.

local status = noctalia.state.get("tardy")

local function render()
  barWidget.setGlyph("calendar-event")

  if status == nil then
    barWidget.setText("")
    barWidget.setTooltip("Tardy: waiting for the calendar")
    return
  end

  barWidget.setText(status.text or "")

  if (status.tooltip or "") == "" then
    barWidget.clearTooltip()
  else
    barWidget.setTooltip(status.tooltip)
  end

  if status.class == "live" then
    barWidget.setColor("primary")
    barWidget.setGlyphColor("primary")
  else
    barWidget.setColor("on_surface")
    barWidget.setGlyphColor("on_surface")
  end
end

noctalia.state.watch("tardy", function(value)
  status = value
  render()
end)

function update()
  noctalia.setUpdateInterval(60000)
  render()
end

function onClick()
  noctalia.runAsync({ "tardy", "open" })
end
