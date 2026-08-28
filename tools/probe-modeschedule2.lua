-- Extended: watch ram_216C-ram_216F (mode-timer schedule) AND the elapsed
-- counter ram_00FB/ram_00FC AND ChaseModeFlag together for the whole
-- recording, to resolve how more than 2 scatter/chase switches can happen
-- if the schedule only ever holds a 2-deep queue that resets to $FF.
local MACHINE = (type(manager.machine) == "function")
                and manager:machine() or manager.machine
local mem = MACHINE.devices[":maincpu"].spaces["program"]
local F = 0
local last = {}
local function chk(name, addr)
  local v = mem:read_u8(addr)
  if v ~= last[name] then
    print(string.format("frame %d %s=%02X", F, name, v))
    last[name] = v
  end
end
emu.register_frame_done(function()
  F = F + 1
  chk("00FF", 0xFF)
  chk("00FB", 0xFB)
  chk("00FC", 0xFC)
  chk("216C", 0x216C)
  chk("216D", 0x216D)
  chk("216E", 0x216E)
  chk("216F", 0x216F)
  if F > 26000 then MACHINE:exit() end
end)
