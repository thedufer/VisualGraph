$ = require('jquery')
VisualGraph = require('./VisualGraph.coffee')

$("#js-stop").hide()

$(document).ready ->
  window._VG = new VisualGraph()
  window.$ = $
  $('#js-run').on 'click', -> _VG.run()
