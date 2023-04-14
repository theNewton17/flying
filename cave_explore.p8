pico-8 cartridge // http://www.pico-8.com
version 34
__lua__

_width=128
_height=64

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

--end world gen
--begin control systems

----util functions
--determines if a specific point on the map is solid
function solid(x,y)
 return fget(cur_world.map[table_2d_pos(x\8,y\8)],0)
 --return fget(full_mget(x\8,y\8),0)
end

--returns true if something at x,y of size w,h is colliding with the map
function mapcoll(phys, x, y)
 local w_2,h_2=phys.w\2,phys.h\2
 return solid(x-w_2, y-h_2)
  or solid(x+w_2-1, y-h_2)
  or solid(x-w_2, y+h_2-1)
  or solid(x+w_2-1, y+h_2-1)
end

----control systems
physics={}
physics.update = function()
 for phys_comp in all(cur_world.phys_comps) do
  local oldx,oldy = phys_comp.x,phys_comp.y
  --velocity
  phys_comp.x += phys_comp.dx
  phys_comp.y += phys_comp.dy
  --acceleration
  phys_comp.dx = mid(-phys_comp.mdx,phys_comp.dx+phys_comp.ddx,phys_comp.mdx)
  phys_comp.dy = mid(-phys_comp.mdy,phys_comp.dy+phys_comp.ddy,phys_comp.mdy)
  --friction
  if(phys_comp.grounded and phys_comp.ddx == 0) phys_comp.dx *= phys_comp.friction

  if mapcoll(phys_comp, phys_comp.x, oldy) then
   phys_comp.x = oldx
   phys_comp.dx = 0
  end
  if mapcoll(phys_comp, oldx, phys_comp.y) then
   phys_comp.y = oldy
   phys_comp.grounded = phys_comp.dy>0
   phys_comp.dy = 0
  end
 end
end

controls={}
controls.update = function()
 local grnd = player.phys_comp.grounded
 if grnd and btnp(2) then
  player.phys_comp.grounded = false
  player.phys_comp.dy = -2
 end

 player.phys_comp.ddx=0
 local left,right = btn(0),btn(1)
 if not (left and right) then
  if(left)player.phys_comp.ddx = (grnd and -0.2 or -0.05)
  if(right)player.phys_comp.ddx = (grnd and 0.2 or 0.05)
 end
end

----components
function new_phys(x, y, w, h, dx, dy)
 local p = {x=x,y=y,w=w,h=h,
  dx=dx,dy=dy,mdx=1,mdy=1.5,
  ddx=0,ddy=0.15,friction=0.8,
  grounded=false}
 add(cur_world.phys_comps, p)
 return p
end

function new_entity(phys_comp)
 local e={
  phys_comp=phys_comp
 }
 add(cur_world.entities, e)
 return e
end

--end control systems
--begin game loop

function _init()
 camx,camy=0,0
 overworld={map={},entities={},phys_comps={}}
 cur_world=overworld

 cur_world.map = rand_world()
 cur_world.map = world_step(cur_world.map)
 cur_world.map = world_step(cur_world.map)
 cur_world.map = world_step(cur_world.map)
 table_to_mapmem(cur_world.map)

 player=new_entity(
  new_phys(8,0,7,7,0,0)
 )
end


function _update()
 controls.update()
 physics.update()
 camx=mid(0,player.phys_comp.x-64,512)
 camy=mid(0,player.phys_comp.y-64,512)
end


function _draw()
 cls()
 --map(0,32,0-camx,0-camy,_width,_height/2)
 --map(0,0,0-camx,256-camy,_width,_height/2)
 camera(camx,camy)
 map(0,32,0,0,_width,_height/2)
 map(0,0,0,256,_width,_height/2)
 print(cur_world.map[table_2d_pos(camx\8,camy\8)], 10, 10)
 spr(0, player.phys_comp.x-4, player.phys_comp.y-4)
end


__gfx__
00cccc004444444455555555aaaaaaaa000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0c0000c04444444455555555aaaaaaaa000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
c070070c4444444455555555aaaaaaaa000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
c000000c4444444455555555aaaaaaaa000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
c070070c4444444455555555aaaaaaaa000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
c007700c4444444455555555aaaaaaaa000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0c0000c04444444455555555aaaaaaaa000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00cccc004444444455555555aaaaaaaa000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__gff__
0001010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
