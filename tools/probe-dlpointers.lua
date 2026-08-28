-- Non-invasive test for what the TAIL of dat_C000 is: dump MARIA's live
-- display-list RAM during gameplay and during the intermission, then
-- decode every graphics pointer. A DL entry pointing into $C4E0-$CA1F
-- proves the region is real display data, with no ROM patching and so no
-- boot-desync confound.
local M=(type(manager.machine)=="function") and manager:machine() or manager.machine
local mem=M.devices[":maincpu"].spaces["program"]
local F=0
local function dump(tag)
  local f=io.open("dl-"..tag..".bin","wb")
  for a=0x1800,0x27FF do f:write(string.char(mem:read_u8(a))) end
  f:close(); print("dumped "..tag.." at frame "..F)
end
emu.register_frame_done(function()
  F=F+1
  if F==2250  then dump("play") end
  if F==13460 then dump("intermission") end
  if F>13470 then M:exit() end
end)
