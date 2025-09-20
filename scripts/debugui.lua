  -- UI Debug Prints
  do
    local addImage = tfm.exec.addImage
    function tfm.exec.addImage(imageId, target, ...)
      print("[addImage] " .. tostring(imageId) .. ", " .. tostring(target))
      return addImage(imageId, target, ...)
    end

    local addTextArea = ui.addTextArea
    function ui.addTextArea(id, ...)
      print("[addTextArea] " .. tostring(id))
      return addTextArea(id, ...)
    end

    local updateTextArea = ui.updateTextArea
    function ui.updateTextArea(id, ...)
      print("[updateTextArea] " .. tostring(id))
      return updateTextArea(id, ...)
    end
  end
  