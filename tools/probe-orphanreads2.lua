-- Follow-up: tag orphan-block reads with the FRAME they happen on, to
-- check whether they cluster at power-on/title-screen setup (consistent
-- with a one-time Maria DMA render) rather than scaling with recording
-- length.
local MACHINE = (type(manager.machine) == "function")
                and manager:machine() or manager.machine
local mem = MACHINE.devices[":maincpu"].spaces["program"]
local cpu = MACHINE.devices[":maincpu"]

local BLOCKS = {
  {name="dat_D49B", lo=0xD49B, hi=0xD49D},
  {name="dat_E9BD", lo=0xE9BD, hi=0xE9CD},
  {name="dat_E9D4", lo=0xE9D4, hi=0xE9D9},
  {name="dat_F83C", lo=0xF83C, hi=0xF846},
}

local F = 0
local TAPS = {}
for _, b in ipairs(BLOCKS) do
  TAPS[b.name] = mem:install_read_tap(b.lo, b.hi, b.name, function(offset, data)
    local pc = cpu.state["PC"].value
    print(string.format("frame %d %s: offset=$%04X data=$%02X PC=$%04X", F, b.name, offset, data, pc))
    return data
  end)
end

emu.register_frame_done(function()
  F = F + 1
  if F > 2000 then MACHINE:exit() end
end)
