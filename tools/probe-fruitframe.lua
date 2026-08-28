local MACHINE = (type(manager.machine) == "function")
                and manager:machine() or manager.machine
local F = 0
local TARGETS = {2990, 3000, 3005, 3011, 3015, 3020, 3030, 3050}
emu.register_frame_done(function()
  F = F + 1
  for _, t in ipairs(TARGETS) do
    if F == t then MACHINE.video:snapshot() end
  end
  if F > 3050 then MACHINE:exit() end
end)
