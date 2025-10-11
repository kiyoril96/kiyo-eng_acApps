local settings = ac.storage {
  isactive = true,
  offsetX =0,
  offsetY =0,
  scale = 2,
  thick = 3
}
local obs = require('shared/utils/obs')
local t0
local t1
local t2
local t3
local car
local forcus 
local uisize
local isinit = false
local uix
local uiy
local wheels = {
  t0dx =  ac.StructItem.float()
  ,t1dx = ac.StructItem.float()
  ,t2dx = ac.StructItem.float()
  ,t3dx = ac.StructItem.float()

  ,t0dy = ac.StructItem.float()
  ,t1dy = ac.StructItem.float()
  ,t2dy = ac.StructItem.float()
  ,t3dy = ac.StructItem.float()

  ,t0fx = ac.StructItem.float()
  ,t1fx = ac.StructItem.float()
  ,t2fx = ac.StructItem.float()
  ,t3fx = ac.StructItem.float()

  ,t0fy = ac.StructItem.float()
  ,t1fy = ac.StructItem.float()
  ,t2fy = ac.StructItem.float()
  ,t3fy = ac.StructItem.float()
}
local rs = nil
function script.init()
  uisize = ac.getUI().windowSize
  uix = uisize.x/4
  uiy = uisize.y/4
  rs = ac.ReplayStream(wheels,nil, 1)
  isinit = true
end

local time = 0
local counter = 0
function script.getState(dt)
  time = time + dt
  forcus = ac.getSim().focusedCar
  car = ac.getCar(forcus)
  local frame = tonumber(ac.getSim().frame)
  if ac.isInReplayMode() then
    frame = ac.getSim().replayCurrentFrame
    t0 = {
      load = car.wheels[0].load
      ,ndSlip = car.wheels[0].ndSlip
      ,dx = ac.readReplayBlob('t0dx'..frame)
      ,dy = ac.readReplayBlob('t0dy'..frame)
      ,fx = ac.readReplayBlob('t0fx'..frame)
      ,fy = ac.readReplayBlob('t0fy'..frame)
    }
    t1 = {
      load = car.wheels[1].load
      ,ndSlip = car.wheels[1].ndSlip
      ,dx = ac.readReplayBlob('t1dx'..frame)
      ,dy = ac.readReplayBlob('t1dy'..frame)
      ,fx = ac.readReplayBlob('t1fx'..frame)
      ,fy = ac.readReplayBlob('t1fy'..frame)
    }
    t2 = {
      load = car.wheels[2].load
      ,ndSlip = car.wheels[2].ndSlip
      ,dx = ac.readReplayBlob('t2dx'..frame)
      ,dy = ac.readReplayBlob('t2dy'..frame)
      ,fx = ac.readReplayBlob('t2fx'..frame)
      ,fy = ac.readReplayBlob('t2fy'..frame)
    }
    t3 = {
      load = car.wheels[3].load
      ,ndSlip = car.wheels[3].ndSlip
      ,dx =  ac.readReplayBlob('t3dx'..frame)
      ,dy =  ac.readReplayBlob('t3dy'..frame)
      ,fx =  ac.readReplayBlob('t3fx'..frame)
      ,fy =  ac.readReplayBlob('t3fy'..frame)
    }
  else
    t0 = car.wheels[0]
    t1 = car.wheels[1]
    t2 = car.wheels[2]
    t3 = car.wheels[3]
    if time >= (ac.getSim().replayFrameMs)/1000 then 
      ac.writeReplayBlob('t0dx'..counter, t0.dx)
      ac.writeReplayBlob('t1dx'..counter, t1.dx)
      ac.writeReplayBlob('t2dx'..counter, t2.dx)
      ac.writeReplayBlob('t3dx'..counter, t3.dx)
      ac.writeReplayBlob('t0dy'..counter, t0.dy)
      ac.writeReplayBlob('t1dy'..counter, t1.dy)
      ac.writeReplayBlob('t2dy'..counter, t2.dy)
      ac.writeReplayBlob('t3dy'..counter, t3.dy)
      ac.writeReplayBlob('t0fx'..counter, t0.fx)
      ac.writeReplayBlob('t1fx'..counter, t1.fx)
      ac.writeReplayBlob('t2fx'..counter, t2.fx)
      ac.writeReplayBlob('t3fx'..counter, t3.fx)
      ac.writeReplayBlob('t0fy'..counter, t0.fy)
      ac.writeReplayBlob('t1fy'..counter, t1.fy)
      ac.writeReplayBlob('t2fy'..counter, t2.fy)
      ac.writeReplayBlob('t3fy'..counter, t3.fy)
      counter = counter + 1
      time = 0
    end
  end

  ac.debug('dx',{t0.dx,t1.dx,t2.dx,t3.dx})
  ac.debug('time',time)
  ac.debug('counter',counter)
  ac.debug('ReplayStream',rs)
end

function script.drawEllipse(center, radius, color, numSegments, thickness)
  ui.pathUnevenArcTo(center, radius, 0, math.pi * 2, numSegments or 12)
  ui.pathStroke(color, true, thickness or 1)
end

function script.scale(x,retio)
  return x*retio
end

function script.setui(car,wheel,offsetx,offsety)
  local offset = vec2(offsetx,offsety)
  local scale = settings.scale * 0.01
  local load = wheel.load
  local DX = wheel.dx
  local DY = wheel.dy
  local FX = wheel.fx
  local FY = wheel.fy
  
  local gforce = vec3():set(car.acceleration*(load),car.acceleration*(load),car.acceleration*(load))*scale
  ac.debug('gforce',gforce)

  --if ac.isInReplayMode() then 
  --  load = wheel.load
  --  DX = 1
  --  DY = 1
  --  FX = 0
  --  FY = 0
  --end
  local radius_x = script.scale(load*DY,scale)
  local radius_y = script.scale(load*DX,scale)
  local fliction_x = script.scale(-(FY),scale)
  local fliction_y = script.scale(FX,scale)
  local ndslip = wheel.ndSlip
  local color_circle = rgbm(wheel.ndSlip,1.5-wheel.ndSlip,0.5,1)
  local color_fliction = rgbm(0,1,1,1)
  local color_slip = rgbm(1,0.5,0,1)
  local segment = 40
  local thick = settings.thick
  

  -- 車体の加速度
  --ui.drawCircleFilled(offset,thick,rgbm(0,0,1,1),segment)
  ui.drawLine(offset,vec2((offset.x+(gforce.x)),(offset.y+(gforce.z))),rgbm(0,0,1,1),thick*1.5)
  ui.drawCircleFilled( vec2((offset.x+(gforce.x)),offset.y+(gforce.z)),thick+2,rgbm(0,0,1,1),segment)
  
  -- 合成
  ui.drawLine(offset,vec2((offset.x+(gforce.x+fliction_x)),(offset.y+(gforce.z+fliction_y))),rgbm(1,1,1,1),thick)
  ui.drawCircleFilled( vec2((offset.x+(gforce.x+fliction_x)),(offset.y+(gforce.z+fliction_y))),thick+2,rgbm(1,1,1,1),segment)

  --摩擦円の描画
  script.drawEllipse(offset,vec2(radius_x,radius_y),rgbm(0,0,0,0.1),segment,thick+10)
  script.drawEllipse(offset,vec2(radius_x,radius_y),color_circle,segment,thick)

  --発生している摩擦力のベクトル
  ui.drawCircleFilled(offset,thick,color_fliction,segment)
  ui.drawLine(offset,vec2(offset.x+fliction_x,offset.y+fliction_y),color_fliction,thick*2)
  ui.drawCircleFilled(vec2(offset.x+fliction_x,offset.y+fliction_y),thick+2,color_fliction,segment)

  --どんだけ滑ってるか
  ui.drawCircleFilled(offset,thick,color_slip,segment)
  ui.drawLine(offset,vec2((offset.x+(fliction_x*ndslip)),(offset.y+(fliction_y*ndslip))),color_slip,thick*2)
  ui.drawCircleFilled( vec2((offset.x+(fliction_x*ndslip)),offset.y+(fliction_y*ndslip)),thick+2,color_slip,segment)
end

function script.ty0()
  script.setui(car,t0,ui.availableSpaceX()/2,ui.availableSpaceY()/2)
end

function script.ty1()
  script.setui(car,t1,ui.availableSpaceX()/2,ui.availableSpaceY()/2)
end

function script.ty2()
  script.setui(car,t2,ui.availableSpaceX()/2,ui.availableSpaceY()/2)
end

function script.ty3()
  script.setui(car,t3,ui.availableSpaceX()/2,ui.availableSpaceY()/2)
end

function script.windowMain()
  if ui.checkbox('active',settings.isactive) then
    settings.isactive = not settings.isactive
  end
  local windowSize = uisize
  local value,changed = ui.slider('##offsetx', settings.offsetX, -(windowSize.x/4), windowSize.x/4, 'OFFSETX: %.0f')
  if changed then settings.offsetX = value end
  local value,changed = ui.slider('##offsety', settings.offsetY, -(windowSize.y/4), windowSize.y/4, 'OFFSETY: %.0f')
  if changed then settings.offsetY = value end

  local value,changed = ui.slider('##scale', settings.scale, 1, 5, 'SCALE: %.02f')
  if changed then settings.scale = value end

  local value,changed = ui.slider('##thick', settings.thick, 1, 10, 'THICKNESS: %.02f')
  if changed then settings.thick = value end
end


local shot
local resolution_retio
obs.register('kiyo-eng_OBSTexture', 'FlictionCircle', obs.Flags.Transparent+obs.Flags.UserSize,
nil
, function (canvas,size)
  canvas:clear()
  resolution_retio = vec2(size.x/uisize.x,size.y/uisize.y)
  local offset = vec2(settings.offsetX*resolution_retio.x,settings.offsetY*resolution_retio.y)
  
  canvas:update(function() 
    script.setui(car,t0,(size.x/4)*1+offset.x,(size.y/4)*1+offset.y)
    script.setui(car,t1,(size.x/4)*3-offset.x,(size.y/4)*1+offset.y)
    script.setui(car,t2,(size.x/4)*1+offset.x,(size.y/4)*3-offset.y)
    script.setui(car,t3,(size.x/4)*3-offset.x,(size.y/4)*3-offset.y)
  end)
end)

function script.simUpdate(dt)
  if isinit == false then script.init() end
  script.getState(dt)
  if settings.isactive then
    ui.transparentWindow('Fliction_circle', vec2(0.0), uisize, function ()
      script.setui(car,t0,uix*1+settings.offsetX,uiy*1+settings.offsetY)
      script.setui(car,t1,uix*3-settings.offsetX,uiy*1+settings.offsetY)
      script.setui(car,t2,uix*1+settings.offsetX,uiy*3-settings.offsetY)
      script.setui(car,t3,uix*3-settings.offsetX,uiy*3-settings.offsetY)
    end)
  end

  --ac.debug('time' , ac.getSim().gameTime)
  ac.debug('replayFrame' , ac.getSim().replayCurrentFrame)
  ac.debug('replayFramems' , ac.getSim().replayFrameMs)
  if ac.getSim().isReplayActive then
    ac.debug('equalsReplay',ac.getSim().frame == ac.getSim().replayCurrentFrame )
  end
end