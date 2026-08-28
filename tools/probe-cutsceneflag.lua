local MACHINE = (type(manager.machine) == "function")
                and manager:machine() or manager.machine
local mem = MACHINE.devices[":maincpu"].spaces["program"]
local F = 0
local last = nil
emu.register_frame_done(function()
  F = F + 1
  if F >= 13350 and F <= 13560 then
    local v = mem:read_u8(0x1D00)
    if v ~= last then
      print(string.format("frame %d ram_1D00=%d", F, v))
      last = v
    end
  end
  if F > 13560 then MACHINE:exit() end
end)
