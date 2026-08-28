local MACHINE = (type(manager.machine) == "function")
                and manager:machine() or manager.machine
local mem = MACHINE.devices[":maincpu"].spaces["program"]
local F = 0
local last40, last2116, lastA6 = nil, nil, nil
emu.register_frame_done(function()
  F = F + 1
  local v40 = mem:read_u8(0x40)
  local v16 = mem:read_u8(0x2116)
  local vA6 = mem:read_u8(0xA6)
  if v40 ~= last40 or v16 ~= last2116 or vA6 ~= lastA6 then
    print(string.format("frame %d ram_0040=%d CurrentFruitType=%d ram_00A6=%d",
      F, v40, v16, vA6))
    last40, last2116, lastA6 = v40, v16, vA6
  end
  if F > 400000 then MACHINE:exit() end
end)
