local MACHINE = (type(manager.machine) == "function")
                and manager:machine() or manager.machine
local F = 0
emu.register_frame_done(function()
  F = F + 1
  if F % 30 == 0 and F <= 2400 then
    MACHINE.video:snapshot()
  end
  if F > 2400 then MACHINE:exit() end
end)
