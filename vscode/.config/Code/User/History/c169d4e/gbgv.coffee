# Helper for getting the selector from a jQuery element
jQuery.fn.extend getPath: ->
  path = undefined
  node = this
  while node.length
    realNode = node[0]
    name = realNode.localName
    if !name
      break
    name = name.toLowerCase()
    parent = node.parent()
    sameTagSiblings = parent.children(name)
    if sameTagSiblings.length > 1
      allSiblings = parent.children()
      index = allSiblings.index(realNode) + 1
      if index > 1
        name += ':nth-child(' + index + ')'
    path = name + (if path then '>' + path else '')
    node = parent
  path

$ ->
  $.reloadAllAutonumeric = () ->
    $('[data-autonumeric]').each ->
      element = $(this)
      selector = element.getPath()
      if AutoNumeric.getAutoNumericElement(selector) == null
        new AutoNumeric(selector, $.parseAutonumericData(element.data('autonumeric')))
        form_parent = element.parents('form')
        form_parent.on('submit', (element) ->
          input_element = $(element.target).find('input[data-autonumeric]')
          input_element.each(() ->
            autonumericElement = AutoNumeric.getAutoNumericElement($(this).getPath())
            $(this).attr('disabled', null)
            value = autonumericElement.getNumber()
            $(this).val(value)
          )
        )
    return

  $.parseAutonumericData = (data) ->
    debugger
    autonumeric_hash = {modifyValueOnWheel: false}
    autonumeric_hash['currencySymbol'] = data.aSign
    autonumeric_hash['currencySymbolPlacement'] = data.pSign
    autonumeric_hash['decimalPlaces'] = data.mDec
    if data.aSign != ' %'
      autonumeric_hash['decimalCharacter'] = data.aDec
      autonumeric_hash['digitGroupSeparator'] = data.aSep
    else
      autonumeric_hash['allowDecimalPadding'] = data.aPad

    if data.vMin
      autonumeric_hash['minimumValue'] = data.vMin

    if data.vMax
      autonumeric_hash['maximumValue'] = data.vMax

    if data.uFos
      autonumeric_hash['unformatOnSubmit'] = data.uFos

    return autonumeric_hash

  $.reloadAllAutonumeric()
  return