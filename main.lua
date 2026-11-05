local player = {x=95,y=315,speed=185}
local witch = {x=340,y=270}
local bigred = {x=740,y=300}
local inventory = {'Friendship Bracelet','Childhood Photo','Lucky Charm','Music Box'}
local lostItems = {}
local hasMirror = false
local state, node, speaker = 'explore', 'start', 'witch'
local message = 'Find your missing best friend. Talk to the Witch and BigRed.'
local font, titleFont
local scenes = {
 witch = {
  start = {text='Witch: Searching for your best friend? Would you like some soup?', choices={{'Thank you. Have you seen her?','kind'},{'Get out of my way!','rude'}}},
  kind = {text='Witch: Your kindness deserves a gift. Take this magic mirror; it reveals hidden truths.',choices={{'Accept the magic mirror','mirror'}}},
  rude = {text='Witch: How rude! My soup may teach you some manners.',choices={{'Drink the soup','poison'},{'Apologize','kind'}}},
  mirror = {text='You have the magic mirror! Continue toward BigRed\'s bridge.',choices={{'Continue','exit'}}},
  poison = {text='The soup was poisoned. In your confusion, you lose a precious keepsake.',choices={{'Continue','exit'}}}
 },
 bigred = {
  start = {text='BigRed: To cross my bridge, answer this: What can you hold without ever touching it?',choices={{'A promise','correct'},{'A shadow','wrong'},{'A flower','wrong'}}},
  correct = {text='BigRed: Correct! I will return one of your lost keepsakes, if I have one.',choices={{'Continue','exit'}}},
  wrong = {text='BigRed: Incorrect. One keepsake is the price of failure.',choices={{'Continue','exit'}}}
 }
}
local function loseItem()
 if #inventory>0 then
  local item=table.remove(inventory)
  table.insert(lostItems,item)
  message='Lost '..item..'. Hope: '..(#inventory*25)..'%'
 end
 if #inventory==0 then state='gameover' end
end
local function restoreItem()
 if #lostItems>0 then
  local item=table.remove(lostItems)
  table.insert(inventory,item)
  message='BigRed returned '..item..'! Hope: '..(#inventory*25)..'%'
 else message='You have not lost any keepsakes. BigRed lets you pass.' end
end
local function nearby(npc)
 return (player.x-npc.x)^2+(player.y-npc.y)^2<90^2
end
function love.load()
 font=love.graphics.newFont(16)
 titleFont=love.graphics.newFont(28)
 love.graphics.setFont(font)
end
function love.update(dt)
 if state~='explore' then return end
 local dx,dy=0,0
 if love.keyboard.isDown('a','left') then dx=dx-1 end
 if love.keyboard.isDown('d','right') then dx=dx+1 end
 if love.keyboard.isDown('w','up') then dy=dy-1 end
 if love.keyboard.isDown('s','down') then dy=dy+1 end
 local length=math.sqrt(dx*dx+dy*dy)
 if length>0 then dx,dy=dx/length,dy/length end
 player.x=math.max(25,math.min(875,player.x+dx*player.speed*dt))
 player.y=math.max(125,math.min(490,player.y+dy*player.speed*dt))
end
local function choose(index)
 local scene=scenes[speaker][node]
 local choice=scene.choices[index]
 if not choice then return end
 local nextNode=choice[2]
 if nextNode=='exit' then state='explore';node='start';return end
 if speaker=='witch' then
  if nextNode=='mirror' then hasMirror=true;message='Magic mirror acquired!' end
  if nextNode=='poison' then loseItem() end
 elseif speaker=='bigred' then
  if nextNode=='correct' then restoreItem() end
  if nextNode=='wrong' then loseItem() end
 end
 node=nextNode
end
function love.keypressed(key)
 if state=='gameover' then
  if key=='r' then love.event.quit('restart') end
  return
 end
 if state=='explore' then
  if key=='e' then
   if nearby(witch) then state='dialogue';speaker='witch';node='start'
   elseif nearby(bigred) then state='dialogue';speaker='bigred';node='start' end
  end
 elseif state=='dialogue' then
  local n=tonumber(key)
  if n then choose(n) end
  if key=='escape' then state='explore';node='start' end
 end
end
local function tree(x,y,s)
 love.graphics.setColor(.30,.18,.11)
 love.graphics.rectangle('fill',x-5*s,y,10*s,24*s)
 love.graphics.setColor(.07,.31,.16)
 love.graphics.circle('fill',x,y,23*s)
 love.graphics.setColor(.12,.43,.23)
 love.graphics.circle('fill',x-7*s,y-7*s,15*s)
end
local function npc(x,y,r,g,b,label)
 love.graphics.setColor(r,g,b)
 love.graphics.circle('fill',x,y-12,13)
 love.graphics.rectangle('fill',x-12,y,24,28)
 love.graphics.setColor(1,1,1)
 love.graphics.print(label,x-34,y-52)
end
function love.draw()
 love.graphics.clear(.12,.25,.14)
 love.graphics.setColor(.43,.35,.23)
 love.graphics.rectangle('fill',0,290,900,82)
 for i=0,9 do
  tree(i*105+18,160,1)
  tree(i*103+28,510,1.05)
 end
 -- Witch's cottage
 love.graphics.setColor(.44,.27,.18)
 love.graphics.rectangle('fill',275,195,130,100)
 love.graphics.setColor(.26,.13,.20)
 love.graphics.polygon('fill',260,200,340,140,420,200)
 love.graphics.setColor(.74,.62,.35)
 love.graphics.rectangle('fill',326,248,28,47)
 -- BigRed's bridge and stream
 love.graphics.setColor(.15,.39,.60)
 love.graphics.rectangle('fill',660,185,85,300)
 love.graphics.setColor(.48,.31,.17)
 love.graphics.rectangle('fill',650,283,105,40)
 for i=0,5 do love.graphics.setColor(.25,.16,.10);love.graphics.line(655+i*18,283,655+i*18,323) end
 npc(witch.x,witch.y,.61,.31,.75,'WITCH')
 npc(bigred.x,bigred.y,.76,.21,.19,'BIGRED')
 npc(player.x,player.y,.35,.58,.95,'YOU')
 love.graphics.setColor(1,1,1)
 love.graphics.setFont(titleFont)
 love.graphics.print('FOREST SIDEQUEST',20,12)
 love.graphics.setFont(font)
 love.graphics.print('WASD: Move   E: Talk   1/2/3: Choose',20,52)
 love.graphics.print('Hope: '..(#inventory*25)..'%   Keepsakes: '..#inventory..'/4   Magic Mirror: '..(hasMirror and 'Yes' or 'No'),20,77)
 love.graphics.printf(message,20,102,860,'left')
 if state=='explore' then
  if nearby(witch) then love.graphics.print('Press E to talk',witch.x-70,witch.y+40) end
  if nearby(bigred) then love.graphics.print('Press E to talk',bigred.x-70,bigred.y+40) end
 end
 love.graphics.setColor(.07,.10,.12,.94)
 love.graphics.rectangle('fill',0,530,900,70)
 love.graphics.setColor(1,1,1)
 love.graphics.print('Keepsakes: '..table.concat(inventory,', '),15,540)
 love.graphics.print('Lost: '..(#lostItems>0 and table.concat(lostItems,', ') or 'none'),15,565)
 if state=='dialogue' then
  love.graphics.setColor(.05,.07,.10,.97)
  love.graphics.rectangle('fill',35,335,830,190,12)
  love.graphics.setColor(1,1,1)
  local scene=scenes[speaker][node]
  love.graphics.printf(scene.text,55,355,790,'left')
  for i,choice in ipairs(scene.choices) do
   love.graphics.printf(i..'. '..choice[1],55,412+(i-1)*29,790,'left')
  end
 end
 if state=='gameover' then
  love.graphics.setColor(0,0,0,.92)
  love.graphics.rectangle('fill',0,0,900,600)
  love.graphics.setColor(1,.8,.8)
  love.graphics.setFont(titleFont)
  love.graphics.printf('YOU LOST ALL HOPE',0,230,900,'center')
  love.graphics.setFont(font)
  love.graphics.printf('Without her treasured memories, she can no longer continue the search.\nPress R to restart.',100,285,700,'center')
 end
end