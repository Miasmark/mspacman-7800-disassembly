-- Traces WHO reads the 4 orphan blocks, once probe-orphanreads.lua/
-- probe-orphanreads2.lua established that every recording does touch
-- them, with a constant/bogus-looking reported PC ($2404) on every hit.
-- Since each block (except dat_D49B, which ends in JMP not RTS) ends in
-- RTS, peek the stack at the moment the RTS opcode byte itself is read --
-- the return address pushed by whatever JSR got here is still sitting at
-- SP+1/SP+2 (MAME's reported SP is already a full effective address, not
-- a page-relative 0-255 byte). RESULT: traced to a real JSR living in RAM
-- (a small self-modifying dispatcher around $238F/$23B7, calling a page-
-- sweep/checksum routine at $23FF whose page-select operand gets patched
-- per call -- seen live patched to $E9/$F8/$D4). That RAM template's own
-- bytes were confirmed (by direct file comparison, see the toolkit/
-- FINDINGS.md write-up) to match a fixed offset inside the actual Atari
-- 7800 system BIOS ROM, not this cartridge -- BIOS boot-time checksum
-- code, external to the game entirely.
local MACHINE = (type(manager.machine) == "function")
                and manager:machine() or manager.machine
local mem = MACHINE.devices[":maincpu"].spaces["program"]
local cpu = MACHINE.devices[":maincpu"]

local BLOCKS = {
  {name="dat_D49B", lo=0xD49B, hi=0xD49D, rts=nil}, -- ends in JMP, not RTS
  {name="dat_E9BD", lo=0xE9BD, hi=0xE9CD, rts=0xE9CD},
  {name="dat_E9D4", lo=0xE9D4, hi=0xE9D9, rts=0xE9D9},
  {name="dat_F83C", lo=0xF83C, hi=0xF846, rts=0xF846},
}

local F = 0
local TAPS = {}
for _, b in ipairs(BLOCKS) do
  TAPS[b.name] = mem:install_read_tap(b.lo, b.hi, b.name, function(offset, data)
    if offset == b.rts then
      local s = cpu.state["SP"].value
      local lo = mem:read_u8((s + 1) & 0xFFFF)
      local hi = mem:read_u8((s + 2) & 0xFFFF)
      local ret = hi * 256 + lo
      local jsr_addr = ret - 2
      local rb0 = mem:read_u8(jsr_addr)
      local rb1 = mem:read_u8(jsr_addr + 1)
      local rb2 = mem:read_u8(jsr_addr + 2)
      print(string.format("frame %d %s RTS hit: SP=$%04X stack-return=$%04X -> JSR site $%04X bytes=%02X %02X %02X",
        F, b.name, s, ret, jsr_addr, rb0, rb1, rb2))
      if rb0 == 0x20 then
        local target = rb2 * 256 + rb1
        local dump = {}
        for i = 0, 47 do
          dump[#dump+1] = string.format("%02X", mem:read_u8(target + i))
        end
        print(string.format("  -> dumping $%04X..$%04X: %s", target, target + 47, table.concat(dump, " ")))
      end
    end
    return data
  end)
end

emu.register_frame_done(function()
  F = F + 1
  if F > 2000 then MACHINE:exit() end
end)
