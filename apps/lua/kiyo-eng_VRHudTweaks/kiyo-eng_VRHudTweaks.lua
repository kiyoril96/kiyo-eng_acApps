local offset 
local offsetkey

local vrhudconfig = ac.INIConfig.load(ac.getFolder(ac.FolderID.ExtCfgUser)..'/vr_tweaks.ini')

local active = vrhudconfig:get('VR_HUD','ENABLED',true)

local move_with_first_view = vrhudconfig:get('VR_HUD','MOVE_WITH_FIRST_PERSON_CAMERA',true)
local move_with_camera =vrhudconfig:get('VR_HUD','MOVE_WITH_CAMERA',false)

local arch=vrhudconfig:get('VR_HUD','SHAPE_ARC',140) -- 80-160
local scale = vrhudconfig:get('VR_HUD','SHAPE_VERTICAL_SCALE',1.0) -- 0.6-1.4
local radius = vrhudconfig:get('VR_HUD','SHAPE_RADIUS',0.4) --0.2-1
local brightness =vrhudconfig:get('VR_HUD','BRIGHTNESS_MULT',1)--0-2

if move_with_first_view then
    offset = vrhudconfig:get('VR_HUD','CAMERA_OFFSET',vec3(0.0,0.0,0.0))
    offsetkey = 'CAMERA_OFFSET'
else 
    offset = vrhudconfig:get('VR_HUD','BASE_OFFSET',vec3(0.0,0.0,0.0))
    offsetkey = 'BASE_OFFSET'
end

local render_mode = vrhudconfig:get('VR_HUD','RENDER_MODE',0) -- 0:Original or 1:See-Through or 2:X-Ray
local opacity = vrhudconfig:get('VR_HUD','RENDER_OCCLUDED_OPACITY',0) -- 0-1


function vrhmdconfigreroad()
    vrhudconfig = ac.INIConfig.load(ac.getFolder(ac.FolderID.ExtCfgUser)..'/vr_tweaks.ini')
    active = vrhudconfig:get('VR_HUD','ENABLED',true)
    move_with_first_view = vrhudconfig:get('VR_HUD','MOVE_WITH_FIRST_PERSON_CAMERA',true)
    move_with_camera =vrhudconfig:get('VR_HUD','MOVE_WITH_CAMERA',false)
    arch=vrhudconfig:get('VR_HUD','SHAPE_ARC',140) -- 80-160
    scale = vrhudconfig:get('VR_HUD','SHAPE_VERTICAL_SCALE',1.0) -- 0.6-1.4
    radius = vrhudconfig:get('VR_HUD','SHAPE_RADIUS',0.4) --0.2-1
    brightness =vrhudconfig:get('VR_HUD','BRIGHTNESS_MULT',1)--0-2

    render_mode = vrhudconfig:get('VR_HUD','RENDER_MODE',0) -- 0:Original or 1:See-Through or 2:X-Ray
    opacity = vrhudconfig:get('VR_HUD','RENDER_OCCLUDED_OPACITY',0) -- 0-1
end

function windowMain(dt)
    if ui.checkbox('Active',active) then
        active = not active
        vrhudconfig:setAndSave('VR_HUD','ENABLED',active)
        vrhmdconfigreroad()
    end

    if ui.checkbox('MOVE_WITH_FIRST_PERSON_CAMERA', move_with_first_view) then
        move_with_first_view = not move_with_first_view
        vrhudconfig:setAndSave('VR_HUD','MOVE_WITH_FIRST_PERSON_CAMERA', move_with_first_view)
        vrhmdconfigreroad()
        if move_with_first_view then
            
            offset = vrhudconfig:get('VR_HUD','CAMERA_OFFSET',vec3(0.0,0.0,0.0))
            offsetkey = 'CAMERA_OFFSET'
        else 
            offset = vrhudconfig:get('VR_HUD','BASE_OFFSET',vec3(0.0,0.0,0.0))
            offsetkey = 'BASE_OFFSET'
        end
    end
    if ui.checkbox('MOVE_WITH_CAMERA',move_with_camera) then
        move_with_camera = not move_with_camera
        vrhudconfig:setAndSave('VR_HUD','MOVE_WITH_CAMERA',move_with_camera)
        vrhmdconfigreroad()
    end

    if active then
        local value,changed = ui.slider('##SHAPE_ARC', arch , 80, 160,'ARCH: %.02f')
        if changed then
            arch = value
            vrhudconfig:setAndSave('VR_HUD','SHAPE_ARC',arch)
            vrhmdconfigreroad()
        end
        local value,changed = ui.slider('##SHAPE_VERTICAL_SCALE', scale , 0.6, 1.4,'VIRTICAL SCALE: %.02f')
        if changed then
            scale = value
            vrhudconfig:setAndSave('VR_HUD','SHAPE_VERTICAL_SCALE',scale)
            vrhmdconfigreroad()
        end
        local value,changed = ui.slider('##SHAPE_RADIUS', radius , 0.2, 1.0,'RADIUS: %.02f')
        if changed then
            radius = value
            vrhudconfig:setAndSave('VR_HUD','SHAPE_RADIUS',radius)
            vrhmdconfigreroad()
        end
        local value,changed = ui.slider('##BRIGHTNESS_MULT', brightness , 0, 2,'BRIGHTNESS: %.02f')
        if changed then
            brightness = value
            vrhudconfig:setAndSave('VR_HUD','BRIGHTNESS_MULT',brightness)
            vrhmdconfigreroad()
        end
        
        local value_x,changed_x = ui.slider('##X', offset.x , -2, 2,'X: %.03f')
        if changed_x then
            offset.x = value_x
        end
        local value_y,changed_y = ui.slider('##Y', offset.y , -2, 2,'Y: %.03f')
        if changed_y then
            offset.y = value_y
        end
        local value_z,changed_z = ui.slider('##Z', offset.z , -2, 2,'Z: %.03f')
        if changed_z then
            offset.z = value_z
        end
        if changed_x or changed_y or changed_z then
            vrhudconfig:setAndSave('VR_HUD',offsetkey,string.format("%.02f,%.02f,%.02f",offset.x,offset.y,offset.z))
            vrhmdconfigreroad()
        end

        if ui.radioButton('Original',render_mode==0) then
            render_mode = 0
        end
        ui.sameLine()
        if ui.radioButton('See-Through',render_mode==1) then
            render_mode = 1
        end
        ui.sameLine()
        if ui.radioButton('X-Ray',render_mode==2) then
            render_mode = 2
        end
        
        vrhudconfig:setAndSave('VR_HUD','RENDER_MODE',render_mode)
        vrhmdconfigreroad()
        
        if render_mode == 1 or render_mode == 2 then
            local value,changed = ui.slider('##RENDER_OCCLUDED_OPACITY', opacity , 0,1,'OPACITY: %.02f')
            if changed then
                opacity = value
                vrhudconfig:setAndSave('VR_HUD','RENDER_OCCLUDED_OPACITY',opacity)
                vrhmdconfigreroad()
            end
        end
    end
end