pico-8 cartridge // http://www.pico-8.com
version 34
__lua__

_width=128
_height=64
_world={}

update_cell = {}
update_cell[0] = function(n)
 if(n>4) return 1
 return 0
end
update_cell[1] = function(n)
 if(n<4) return 0
 if(n==8) return 2
 return 1
end
update_cell[2] = function(n)
 if(n<12) return 1
 if(n==16) return 3
 return 2
end
update_cell[3] = function(n)
 if(n<24) return 2
 return 3
end

function count_neighbors(world,x,y)
 c=0
 for i=y-1,y+1 do
  if i<0 then
   --top layer is not filled
  elseif i<0 or i>_height-1 then
   c+=3
  else
   for j=x-1,x+1 do
    if j<0 or j>_width-1 then
     c+=1
    elseif i~=y or j~=x then
     c+=world[table_2d_pos(j,i)]
    end
   end
  end
 end
 return c
end

function table_2d_pos(x,y)
 return 1+y*_width+x
end

--returns a table of 8192 1-byte values
function mapmem_to_table()
 return pack(peek(0x1000,8192))
end

--expects a table of 8192 1-byte values
function table_to_mapmem(tbl)
 poke(0x1000,unpack(tbl))
end

--weird loop dimensions explanation
--world is 128 tiles wide by 64 tiles tall
--128*64=8192
--use 32bits of randomness
--8192/32=256
function rand_world()
 w={}
 for i=0,255 do
  num=rnd(-1)
  --num = num <<> i
  for j=1,32 do
   w[i*32+j] = (num <<> j) & 1
  end
 end

 return w
end

function world_step(w)
 local nw={}
 for i=0,_height-1 do
  for j=0,_width-1 do
   local curval=w[table_2d_pos(j,i)]
   local n=count_neighbors(w,j,i)
   nw[table_2d_pos(j,i)] = update_cell[curval](n)
  end
 end
 return nw
end


function _init()
 camx,camy=0,0
 world = rand_world()
 --world = world_step(world)
 --world = world_step(world)
 --world = world_step(world)
 table_to_mapmem(world)
end


function _update()
 if(btn(0))camx-=1
 if(btn(1))camx+=1
 if(btn(2))camy-=1
 if(btn(3))camy+=1
 if btnp(4) then
  world = world_step(world)
  table_to_mapmem(world)
 end
end


function _draw()
 cls()
 map(0,32,0-camx,0-camy,_width,_height/2)
 map(0,0,0-camx,256-camy,_width,_height/2)
 print(world[table_2d_pos(camx\8,camy\8)], 10, 10)
end

__gfx__
00000000777777771111111122222222000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000777777771111111122222222000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700777777771111111122222222000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000777777771111111122222222000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000777777771111111122222222000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700777777771111111122222222000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000777777771111111122222222000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000777777771111111122222222000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001