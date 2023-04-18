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

--returns true if a circle at x1,y1 of radius r1
--is touching a circle at x2,y2 of radius r2
function circ_circ(x1,y1,r1,x2,y2,r2)
 dist_x = x1 - x2
 dist_y = y1 - y2
 rad_sum = r1 + r2
 return dist_x*dist_x + dist_y*dist_y <= rad_sum*rad_sum+1
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
  dx=dx,dy=dy,mdx=1,mdy=1.8,
  ddx=0,ddy=0.15,friction=0.7,
  grounded=false}
  
 p.update = function(self)
  if(self.dy>0) self.grounded=false
  local oldx,oldy = self.x,self.y
  --velocity
  self.x += self.dx
  self.y += self.dy
  --acceleration
  self.dx = mid(-self.mdx,self.dx+self.ddx,self.mdx)
  self.dy = mid(-self.mdy,self.dy+self.ddy,self.mdy)
  --friction
  if(self.grounded and self.ddx == 0) self.dx *= self.friction

  if mapcoll(self, self.x, oldy) then
   self.x = oldx
   self.dx = 0
  end
  
  if mapcoll(self, oldx, self.y) then
   self.y = oldy
   self.grounded = self.dy>0
   self.dy = 0
  end
 end

 return p
end

----entities
function new_wurm(x, y, len, goal)
 local s = {}
 s.body={}
 for i=1,len do
  add(s.body,{x,y})
 end
 s.len=len
 s.size=4
 s.i=0
 s.turn=0
 s.velocity=1
 s.goal=goal.phys_comp
 s.support=nil
 s.accuracy=rnd(100)+1 --lower accuracy means smarter wurm
 --s.fall_timer=0 --frames wurm has spent above ground before arcing downward

 s.update = function(self)
  new_head=self.body[1+self.i]
  local tail_in_ground = solid(new_head[1],new_head[2])
  old_head=self.body[1+(self.i-1)%#self.body]
  local head_in_ground = solid(old_head[1],old_head[2])

  if self.support == nil and not head_in_ground then
   self.support = {old_head[1],old_head[2]}
  elseif self.support ~= nil and head_in_ground then
   self.support = nil
  end
  
  local midpt_supported = true
  if self.support ~= nil then
   midpt_supported = circ_circ(old_head[1],old_head[2],self.len/2,self.support[1],self.support[2],1)
  end

  --last segment becomes first segment
  --means all other segments don't need to move, efficient
  new_head[1]=old_head[1]+cos(self.turn)*self.velocity
  new_head[2]=old_head[2]+sin(self.turn)*self.velocity

  --aim downwards if too far out of terrain
  local supported = head_in_ground or (tail_in_ground and midpt_supported)
  local goal = supported and self.goal or {x=new_head[1],y=new_head[2]+100}
  local accuracy = supported and self.accuracy or 4

  local diff = (atan2(goal.x - new_head[1],goal.y - new_head[2]) - self.turn + 0.5) % 1 - 0.5
  --turn towards the target with v/a speed. sin(a/100)/100 is the "wiggle"
  self.turn += ((diff<-0.5 and diff+1 or diff) * self.velocity/accuracy + sin(accuracy/100)/100)

  self.accuracy-=1
  self.i=(self.i+1) % #self.body
  if (self.accuracy<5) self.accuracy=rnd(100)+1
 end

 s.draw = function(self)
  for seg in all(self.body) do
   circfill(seg[1], seg[2], self.size, 9)
  end
  if(self.support ~= nil) pset(self.support[1],self.support[2],8)
 end

 add(cur_world.entities, s)
 return s
end

function new_player(x,y)
 local p = {phys_comp=new_phys(x,y,7,7,0,0)}

 p.update = function(self)
  --player controls
  local grnd = self.phys_comp.grounded
  if grnd and btnp(2) then
   self.phys_comp.grounded = false
   self.phys_comp.dy = -self.phys_comp.mdy
  end

  self.phys_comp.ddx=0
  local left,right = btn(0),btn(1)
  if not (left and right) then
   if(left) self.phys_comp.ddx = (grnd and -0.2 or -0.05)
   if(right) self.phys_comp.ddx = (grnd and 0.2 or 0.05)
  end

  p.phys_comp:update()
 end

 p.draw = function(self)
  spr(0, self.phys_comp.x-4, self.phys_comp.y-4)
 end

 add(cur_world.entities, p)
 return p
end

--begin game loop

function _init()
 camx,camy=0,0
 overworld={map={},entities={}}
 cur_world=overworld

 cur_world.map = rand_world()
 cur_world.map = world_step(cur_world.map)
 cur_world.map = world_step(cur_world.map)
 cur_world.map = world_step(cur_world.map)
 table_to_mapmem(cur_world.map)

 player=new_player(0,0)
 --new_wurm(60,60,64,player)
end


function _update()
 for e in all(cur_world.entities) do
  e:update()
 end
 camx=mid(0,player.phys_comp.x-64,512)
 camy=mid(0,player.phys_comp.y-64,512)
end


function _draw()
 cls()
 camera(camx,camy)
 map(0,32,0,0,_width,_height/2)
 map(0,0,0,256,_width,_height/2)
 --print(cur_world.map[table_2d_pos(camx\8,camy\8)], 10, 10)
 for e in all(cur_world.entities) do
  e:draw()
 end
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
