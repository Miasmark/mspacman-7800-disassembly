-- Check ram_00A4 (the newly-suspected lives counter, confirmed via
-- rom:sub_F79E's icon-drawing use and rom:sub_F6E8's extra-life
-- increment) across the whole recording for any change -- would confirm
-- a death or extra-life event actually occurring live.
local MACHINE = (type(manager.machine) == "function")
                and manager:machine() or manager.machine
local mem = MACHINE.devices[":maincpu"].spaces["program"]
local F = 0
local last, lastA3 = nil, nil
emu.register_frame_done(function()
  F = F + 1
  local v = mem:read_u8(0xA4)
  local v3 = mem:read_u8(0xA3)
  if v ~= last or v3 ~= lastA3 then
    print(string.format("frame %d ram_00A4=%d ram_00A3=%d", F, v, v3))
    last, lastA3 = v, v3
  end
end)
