-- Snapshot the screen at a specific frame to check the on-screen lives
-- display visually.
local MACHINE = (type(manager.machine) == "function")
                and manager:machine() or manager.machine
local F = 0
emu.register_frame_done(function()
  F = F + 1
  if F == 2200 or F == 21500 then
    MACHINE:popmessage(string.format("snap at %d", F))
    MACHINE.video:snapshot()
  end
  if F > 21600 then MACHINE:exit() end
end)
