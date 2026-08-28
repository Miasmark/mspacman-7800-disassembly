-- sub_F61A (rom:F61A) is the score-add routine: it zeroes ram_00B9/BA,
-- then BCD-adds ram_00B9..00BC into the current player's 4-byte score
-- (ram_0046-0049 for player 1, gated on ram_0042/ram_0045 both zero).
-- Since 00B9/00BA are always zeroed by the routine itself, only 00BB
-- (hundreds/thousands digit pair) and 00BC (tens/ones digit pair) ever
-- carry a real nonzero delta -- i.e. the actual point value being
-- awarded, in BCD, up to 9999. Taps writes to both plus the routine's
-- own entry, PC-tagged, to catch every distinct point value live.
local MACHINE = (type(manager.machine) == "function")
                and manager:machine() or manager.machine
local mem = MACHINE.devices[":maincpu"].spaces["program"]
local cpu = MACHINE.devices[":maincpu"]
local F = 0

local function tap(name)
  return function(offset, data)
    local pc = cpu.state["PC"].value
    print(string.format("%s frame %d pc=$%04X val=$%02X", name, F, pc, data))
    return data
  end
end

TAPBB = mem:install_write_tap(0x00BB, 0x00BB, "bb", tap("BB"))
TAPBC = mem:install_write_tap(0x00BC, 0x00BC, "bc", tap("BC"))

local ENTRY = 0xF61A
local last_pc = 0
emu.register_frame_done(function()
  F = F + 1
  if F > 8000 then MACHINE:exit() end
end)
