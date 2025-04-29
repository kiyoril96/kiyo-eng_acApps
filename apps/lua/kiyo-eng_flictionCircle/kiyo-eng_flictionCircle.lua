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
function script.init()
  uisize = ac.getUI().windowSize
  uix = uisize.x/4
  uiy = uisize.y/4
  isinit = true
end

-- local datastore = {}

function script.getState()
  forcus = ac.getSim().focusedCar
  car = ac.getCar(forcus)
  t0 = car.wheels[0]
  t1 = car.wheels[1]
  t2 = car.wheels[2]
  t3 = car.wheels[3]
  -- datastore[ac.getSim().replayFrames] = {t0,t1,t2,t3} 
end

function script.drawEllipse(center, radius, color, numSegments, thickness)
  ui.pathUnevenArcTo(center, radius, 0, math.pi * 2, numSegments or 12)
  ui.pathStroke(color, true, thickness or 1)
end

function script.scale(x,retio)
  return x*retio
end

function script.setui(wheel,offsetx,offsety)
  local offset = vec2(offsetx,offsety)
  local scale = settings.scale * 0.01
  local load = wheel.load
  local DX = wheel.dx
  local DY = wheel.dy
  local FX = wheel.fx
  local FY = wheel.fy
  if ac.isInReplayMode() then 
    load = wheel.load
    DX = 1
    DY = 1
    FX = 0
    FY = 0
  end
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
  script.setui(t0,ui.availableSpaceX()/2,ui.availableSpaceY()/2)
end

function script.ty1()
  script.setui(t1,ui.availableSpaceX()/2,ui.availableSpaceY()/2)
end

function script.ty2()
  script.setui(t2,ui.availableSpaceX()/2,ui.availableSpaceY()/2)
end

function script.ty3()
  script.setui(t3,ui.availableSpaceX()/2,ui.availableSpaceY()/2)
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
obs.register('kiyo-eng_OBSTexture', 'FlictionCircle', obs.Flags.Transparent+obs.Flags.UserSize,
nil
, function (canvas,size)
  canvas:clear()
  
  
  canvas:update(function() 
    script.setui(t0,(size.x/4)*1+settings.offsetX,(size.y/4)*1+settings.offsetY)
    script.setui(t1,(size.x/4)*3-settings.offsetX,(size.y/4)*1+settings.offsetY)
    script.setui(t2,(size.x/4)*1+settings.offsetX,(size.y/4)*3-settings.offsetY)
    script.setui(t3,(size.x/4)*3-settings.offsetX,(size.y/4)*3-settings.offsetY)
  end)
end)

function script.simUpdate()
  if isinit == false then script.init() end
  script.getState()
  if settings.isactive then
    ui.transparentWindow('Fliction_circle', vec2(0.0), uisize, function ()
      script.setui(t0,uix*1+settings.offsetX,uiy*1+settings.offsetY)
      script.setui(t1,uix*3-settings.offsetX,uiy*1+settings.offsetY)
      script.setui(t2,uix*1+settings.offsetX,uiy*3-settings.offsetY)
      script.setui(t3,uix*3-settings.offsetX,uiy*3-settings.offsetY)
    end)
  end

  ac.debug('curFrame' , ac.getSim().frame)
  ac.debug('replayFrame' , ac.getSim().replayCurrentFrame)
  ac.debug('replayFrames' , ac.getSim().replayFrames)
  if ac.getSim().isReplayActive then
    ac.debug('equalsReplay',ac.getSim().frame == ac.getSim().replayCurrentFrame )
  end
end