-- Does anything -- CPU instruction fetch or a plain data read -- ever
-- touch the 4 orphan blocks (dat_D49B, dat_E9BD, dat_E9D4, dat_F83C)
-- during an actual recording? Read-tapped (not PC-sampled) so it can't
-- miss a momentary visit the way frame-boundary sampling would.
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

local hits = {}
local TAPS = {}
for _, b in ipairs(BLOCKS) do
  hits[b.name] = 0
  TAPS[b.name] = mem:install_read_tap(b.lo, b.hi, b.name, function(offset, data)
    hits[b.name] = hits[b.name] + 1
    local pc = cpu.state["PC"].value
    if hits[b.name] <= 20 then
      print(string.format("%s: offset=$%04X data=$%02X PC=$%04X", b.name, offset, data, pc))
    end
    return data
  end)
end

local function dump_final()
  print("=== FINAL TALLY ===")
  for _, b in ipairs(BLOCKS) do
    print(string.format("%s: %d hits", b.name, hits[b.name]))
  end
end

local F = 0
emu.register_frame_done(function()
  F = F + 1
  if F % 5000 == 0 then
    print(string.format("progress frame %d", F))
  end
  if F > 30000 then
    dump_final()
    MACHINE:exit()
  end
end)
