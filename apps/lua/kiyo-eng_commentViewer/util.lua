
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

-- リンクテキスト出してクリックしたらブラウザを開く
function ui.clickableHyperLink(text,hyperlinkColer)
    if ui.textHyperlink(text,hyperlinkColer) then os.openURL(text) end
end