local MACHINE = (type(manager.machine) == "function")
                and manager:machine() or manager.machine
local mem = MACHINE.devices[":maincpu"].spaces["program"]
local F = 0
local TARGETS = {3011, 5485, 7372}
emu.register_frame_done(function()
  F = F + 1
  for _, t in ipairs(TARGETS) do
    if F == t then
      print(string.format("frame %d ram_2116=%d ram_2124=%d",
        F, mem:read_u8(0x2116), mem:read_u8(0x2124)))
    end
  end
  if F > 7400 then MACHINE:exit() end
end)
