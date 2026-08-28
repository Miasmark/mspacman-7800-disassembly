-- Dump Maria's live working display-list area ($1F00-$1FFF) plus the
-- zone/DLL pointer region to a raw binary file, for dlwalk.py to decode
-- -- to find the real graphics-mode/pointer conventions this game uses,
-- as a way to finally pin down dat_C000's identity.
local MACHINE = (type(manager.machine) == "function")
                and manager:machine() or manager.machine
local mem = MACHINE.devices[":maincpu"].spaces["program"]
local F = 0
emu.register_frame_done(function()
  F = F + 1
  if F == 2200 then
    local f = io.open("dl-dump.bin", "wb")
    for a = 0x1E00, 0x1FFF do
      f:write(string.char(mem:read_u8(a)))
    end
    f:close()
    print("dumped $1E00-$1FFF to dl-dump.bin")
  end
  if F > 2210 then MACHINE:exit() end
end)
