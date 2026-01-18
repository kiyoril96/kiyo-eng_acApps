-- radius vec2(縦,横)
function script.drawEllipse(center, radius, color, numSegments, thickness)
  ui.pathUnevenArcTo(center, radius, 0, math.pi * 2.1 , numSegments or 12)
  ui.pathStroke(color, true, thickness or 1)
end

-- 右クリックでリセットできるスライダー
function ui.resetableSlider(label,value,min,max,format,power,defaultValue)
    local ref = refnumber(value)
    local changed = false
    if ui.slider(label, ref, min, max, format,power) then 
        value = ref.value 
        changed = true
    end
    if ui.itemClicked(ui.MouseButton.Right, true) then
        value = defaultValue
        changed = true
    end
    return value,changed
end