-- Decisive test for the ram_0067=5 lives-counter hypothesis: patch it to
-- 1 partway through the recording and snapshot before/after. If it's
-- really the lives counter, the on-screen icon row should visibly drop.
local MACHINE = (type(manager.machine) == "function")
                and manager:machine() or manager.machine
local mem = MACHINE.devices[":maincpu"].spaces["program"]
local F = 0
emu.register_frame_done(function()
  F = F + 1
  if F == 2200 then
    MACHINE.video:snapshot()  -- before
  end
  if F == 2210 then
    mem:write_u8(0x67, 1)
    print(string.format("frame %d: patched ram_0067 to 1", F))
  end
  if F == 2215 then
    MACHINE.video:snapshot()  -- after
  end
  if F > 2220 then MACHINE:exit() end
end)
