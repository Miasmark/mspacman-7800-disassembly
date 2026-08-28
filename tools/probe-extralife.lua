-- Confirms the extra-life countdown (ram_004A/ram_004B) initializes to
-- the value found in dat_D04C ($09,$99) and counts down as points are
-- scored, matching the newly-traced rom:sub_F663 mechanism.
local MACHINE = (type(manager.machine) == "function")
                and manager:machine() or manager.machine
local mem = MACHINE.devices[":maincpu"].spaces["program"]
local F = 0
local last = nil
emu.register_frame_done(function()
  F = F + 1
  local a, b = mem:read_u8(0x4A), mem:read_u8(0x4B)
  local v = string.format("%02X%02X", a, b)
  if v ~= last then
    print(string.format("frame %d ExtraLifeCountdown=%s", F, v))
    last = v
  end
  if F > 3000 then MACHINE:exit() end
end)
