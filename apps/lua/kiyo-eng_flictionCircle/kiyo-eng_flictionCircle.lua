local obs = require('shared/utils/obs')
local t0
local t1
local t2
local t3
local car
local focus 
local uisize
local isinit = false
local uix
local uiy
local tyresConfig
local settings = ac.storage {
  isactive = true,
  gforce = false,
  composite = false,
  relativeTyer = false,
  guage = false,
  offsetX =0,
  offsetY =0,
  scale = 2,
  thick = 3
}

-- radius vec2(縦,横)
function script.drawEllipse(center, radius, color, numSegments, thickness)
  ui.pathUnevenArcTo(center, radius, 0, math.pi * 2.1 , numSegments or 12)
  ui.pathStroke(color, true, thickness or 1)
end

function script.init()
  uisize = ac.getUI().windowSize
  uix = uisize.x/4
  uiy = uisize.y/4
  tyresConfig = ac.INIConfig.carData(ac.getSim().focusedCar,'tyres.ini')
  
  -- obs init 
  local resolution_retio
  obs.notify(function ()
    obs.register('kiyo-eng_OBSTexture', 'FlictionCircle', obs.Flags.Transparent+obs.Flags.UserSize
    , function (size)
      resolution_retio = vec2(size.x/uisize.x,size.y/uisize.y)
    end
    , function (canvas,size)
      local offset = vec2(settings.offsetX*resolution_retio.x,settings.offsetY*resolution_retio.y)
      canvas:clear()
      canvas:update(function(dt) 
        script.setui(car,t0,(size.x/4)*1+offset.x,(size.y/4)*1+offset.y,'FL',dt)
        script.setui(car,t1,(size.x/4)*3-offset.x,(size.y/4)*1+offset.y,'FR',dt)
        script.setui(car,t2,(size.x/4)*1+offset.x,(size.y/4)*3-offset.y,'RL',dt)
        script.setui(car,t3,(size.x/4)*3-offset.x,(size.y/4)*3-offset.y,'RR',dt)
      end)
  end)
  end
  )
  isinit = true
end

local curFocus
function script.getState()
  focus = ac.getSim().focusedCar
  if curFocus ~= focus then 
    curFocus = focus
    tyresConfig = nil
    tyresConfig = ac.INIConfig.carData(curFocus,'tyres.ini')
  end
  car = ac.getCar(curFocus)
  t0 = car.wheels[0]
  t1 = car.wheels[1]
  t2 = car.wheels[2]
  t3 = car.wheels[3]
end

function script.scale(x,retio)
  return x*retio
end

local color_circle = rgbm() 
local color_circle_alt = rgbm(0,0,0,0.1)
local color_fliction = rgbm(0,1,1,1)
local color_slip = rgbm(1,0.5,0,1)
local color_gauge = rgbm(1,1,1,1)
local color_gauge_alt = rgbm(1,0,1,1)
local segment = 40
local thick = 0
local angle = 0
local lastVel = {}
lastVel[0] = vec3()
lastVel[1] = vec3()
lastVel[2] = vec3()
lastVel[3] = vec3()
function script.setui(car,wheel,offsetx,offsety,tyreLabel,dt)
  local tyerIndex
  if tyreLabel == 'FL' then tyerIndex=0
  elseif tyreLabel == 'FR' then tyerIndex=1
  elseif tyreLabel == 'RL' then tyerIndex=2
  elseif tyreLabel == 'RR' then tyerIndex=3
  end
  local offset = vec2(offsetx,offsety)
  local scaleRetio = settings.scale * 0.01
  local load = wheel.load
  local DX = wheel.dx
  local DY = wheel.dy
  local FX = wheel.fx
  local FY = wheel.fy
  local mass_1g = car.mass*2.45 -- 1/4N=9.8/4
  local setctionName = ''
  if tyreLabel == 'FL'or tyreLabel == 'FR' then setctionName = 'FRONT' else setctionName = 'REAR' end
  local dxRef = tyresConfig:get(setctionName,'DX_REF',1)*wheel.surfaceGrip
  local dyRef = tyresConfig:get(setctionName,'DY_REF',1)*wheel.surfaceGrip
  --local acc = vec3()
  --local foce = vec3()
  --local velocity = (wheel.transform):inverse():transformVector(wheel.velocity)

  --if lastVel[tyerIndex] ~= vec3() then
  --  acc = (velocity - lastVel[tyerIndex]) / dt
  --  foce = (load/9.8)*acc
  --end
  --lastVel[tyerIndex] = velocity

  if ac.isInReplayMode() then 
    local load_remap = math.remap(load,0,mass_1g,-1,0)
    local calc_dx = ((dxRef)^(dxRef-load_remap))
    local calc_dy = ((dyRef)^(dyRef-load_remap))
    load = wheel.load
      DX = calc_dx
      DY = calc_dy
    if load > tyresConfig:get(setctionName,'FZ0',1)*9.8 then
      DX = calc_dx * (math.log(( load-(tyresConfig:get(setctionName,'FZ0',1.0)*9.8) ),tyresConfig:get(setctionName,'LS_EXPX',1)))
      DY = calc_dy * (math.log(( load-(tyresConfig:get(setctionName,'FZ0',1.0)*9.8) ),tyresConfig:get(setctionName,'LS_EXPY',1)))
    end
    FX = 0
    FY = 0

  end

  -- DXが縦 DYが横
  local radius_x = script.scale(load*DX,scaleRetio)
  local radius_y = script.scale(load*DY,scaleRetio)
  local fliction_x = script.scale(FX,scaleRetio)
  local fliction_y = script.scale(FY,scaleRetio)
  local ndslip = wheel.ndSlip
  local gaugeSize = script.scale(mass_1g*dxRef,scaleRetio)
  local gauge2GSize = script.scale(mass_1g*2*dxRef,scaleRetio)
  thick = settings.thick
  color_circle = rgbm(wheel.ndSlip,1.5-wheel.ndSlip,0.5,1)
  -- 枠
  if settings.guage then 
    ui.drawLine(offset-vec2(gauge2GSize,0),offset+vec2(gauge2GSize,0),color_gauge,thick*0.3)
    ui.drawLine(offset-vec2(0,gauge2GSize),offset+vec2(0,gauge2GSize),color_gauge,thick*0.3)
    ui.drawCircle(offset,gaugeSize,color_gauge,segment,thick*0.3)
    ui.drawCircle(offset,gauge2GSize,color_gauge,segment,thick*0.3)
  end

  ui.beginRotation()
    ui.drawLine(offset-vec2(0,gauge2GSize),offset+vec2(0,gauge2GSize),rgbm(1,1,0,1),thick*0.7)
  ui.endPivotRotation((wheel.slipAngle)+90, offset)

  -- トー角に合わせてUIを動かすか
  if settings.relativeTyer then angle = -(wheel.toeIn) else angle = 0 end 
  ui.beginRotation()

  --最大摩擦力（摩擦円）
  if settings.guage then
    ui.drawLine(offset-vec2(gaugeSize,0),offset+vec2(gaugeSize,0),color_gauge_alt,thick*0.5)
    ui.drawLine(offset-vec2(0,gaugeSize),offset+vec2(0,gaugeSize),color_gauge_alt,thick*0.5)
  end
  script.drawEllipse(offset,vec2(radius_x,radius_y),color_circle_alt,segment,thick*2)
  script.drawEllipse(offset,vec2(radius_x,radius_y),color_circle,segment,thick)
  --test 
  --local load_remap = math.remap(load,0,mass_1g,-1,0)
  --local calc_dx = ((dxRef)^(dxRef-load_remap))
  --local calc_dy = ((dyRef)^(dyRef-load_remap))
  --local test_calc_dx = calc_dx
  --local test_calc_dy = calc_dy
  --if load > tyresConfig:get(setctionName,'FZ0',1)*9.8 then
  --  test_calc_dx = calc_dx * (math.log(( load-(tyresConfig:get(setctionName,'FZ0',1.0)*9.8) ),tyresConfig:get(setctionName,'LS_EXPX',1)))
  --  test_calc_dy = calc_dy * (math.log(( load-(tyresConfig:get(setctionName,'FZ0',1.0)*9.8) ),tyresConfig:get(setctionName,'LS_EXPY',1)))
  --end
  --script.drawEllipse(offset,vec2(script.scale(load*test_calc_dy,scaleRetio),script.scale(load*test_calc_dx,scaleRetio)),rgbm(1,1,0,1),segment,thick)
  --発生している摩擦力のベクトル
  ui.drawCircleFilled(offset,thick,color_fliction,segment)
  ui.drawLine(offset,vec2(offset.x+fliction_x,offset.y+fliction_y),color_fliction,thick*2)
  ui.drawCircleFilled(vec2(offset.x+fliction_x,offset.y+fliction_y),thick+2,color_fliction,segment)
  --スリップ率
  ui.drawCircleFilled(offset,thick,color_slip,segment)
  ui.drawLine(offset,vec2((offset.x+(fliction_x*ndslip)),(offset.y+(fliction_y*ndslip))),color_slip,thick*2)
  ui.drawCircleFilled( vec2((offset.x+(fliction_x*ndslip)),offset.y+(fliction_y*ndslip)),thick+2,color_slip,segment)
  if not ac.isInReplayMode() then 
    local gforce = vec3():set((car.acceleration)*(load))*scaleRetio
    --local gforce = -foce/100
    local rotatedFoce = gforce:rotate(quat.fromAngleAxis(-math.rad(wheel.toeIn), vec3(0,1,0)))
    if settings.gforce then 
      -- 車体の加速度
      ui.drawCircleFilled(offset,thick,rgbm(0,0,1,1),segment)
      ui.drawLine(offset,vec2((offset.x+(rotatedFoce.z)),(offset.y+(-rotatedFoce.x))),rgbm(0,0,1,1),thick*1.5)
      ui.drawCircleFilled( vec2((offset.x+(rotatedFoce.z)),(offset.y+(-rotatedFoce.x))),thick+2,rgbm(0,0,1,1),segment)
    end
    if settings.composite then
      -- 合成
      ui.drawCircleFilled(offset,thick,color_gauge,segment)
      ui.drawLine(offset,vec2((offset.x+(rotatedFoce.z+fliction_x)),(offset.y+(-rotatedFoce.x+fliction_y))),color_gauge,thick*1.5)
      ui.drawCircleFilled( vec2((offset.x+(rotatedFoce.z+fliction_x)),(offset.y+(-rotatedFoce.x+fliction_y))),thick+2,color_gauge,segment)
    end
  end

  ui.endPivotRotation(angle, offset)
  
  -- ac.debug(tyerIndex..'.'..tyreLabel..'_dx',DX)
  -- ac.debug(tyerIndex..'.'..tyreLabel..'_dy',DY)
  -- ac.debug(tyerIndex..'.'..tyreLabel..'_fx',FX)
  -- ac.debug(tyerIndex..'.'..tyreLabel..'_fy',FY)
  -- ac.debug(tyerIndex..'.'..tyreLabel..'_calc_dx',test_calc_dx)
  -- ac.debug(tyerIndex..'.'..tyreLabel..'_calc_dy',test_calc_dy)
  ac.debug(tyerIndex..'.'..tyreLabel..'_SA',wheel.slipAngle)
  ac.debug(tyerIndex..'.'..tyreLabel..'_Toe',wheel.toeIn)
  ac.debug(tyerIndex..'.'..tyreLabel..'_accel',acc)
  ac.debug(tyerIndex..'.'..tyreLabel..'_foce',foce)
  
end

-- FL
function script.ty0(dt) script.setui(car,t0,ui.availableSpaceX()/2,ui.availableSpaceY()/2,'FL',dt) end
-- FR
function script.ty1(dt) script.setui(car,t1,ui.availableSpaceX()/2,ui.availableSpaceY()/2,'FR',dt) end
-- RL
function script.ty2(dt) script.setui(car,t2,ui.availableSpaceX()/2,ui.availableSpaceY()/2,'RL',dt) end
-- RR
function script.ty3(dt) script.setui(car,t3,ui.availableSpaceX()/2,ui.availableSpaceY()/2,'RR',dt) end

function script.windowMain()
  if ui.checkbox('Active',settings.isactive) then settings.isactive = not settings.isactive end
  if ui.checkbox('Gforce Vector',settings.gforce) then settings.gforce = not settings.gforce end
  if ui.checkbox('Composite Vector',settings.composite) then settings.composite = not settings.composite end
  if ui.checkbox('RelativeTyer',settings.relativeTyer) then settings.relativeTyer = not settings.relativeTyer end
  if ui.checkbox('Guage',settings.guage) then settings.guage = not settings.guage end
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

function script.simUpdate(dt)
  if isinit == false then script.init() end
  script.getState()
  if settings.isactive then
    ui.transparentWindow('Fliction_circle', vec2(0.0), uisize, function ()
      script.setui(car,t0,uix*1+settings.offsetX,uiy*1+settings.offsetY,'FL',dt)
      script.setui(car,t1,uix*3-settings.offsetX,uiy*1+settings.offsetY,'FR',dt)
      script.setui(car,t2,uix*1+settings.offsetX,uiy*3-settings.offsetY,'RL',dt)
      script.setui(car,t3,uix*3-settings.offsetX,uiy*3-settings.offsetY,'RR',dt)
    end)
  end
  ac.debug('0_lastvel' ,lastVel[1])
end