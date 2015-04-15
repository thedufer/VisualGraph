$ = require('jquery')
VisualGraph = require('./VisualGraph.coffee')

$("#js-stop").hide()

$(document).ready ->
  window._VG = new VisualGraph()
  window.$ = $
  window.d3 = require('d3-browserify')
  $('#js-run').on 'click', -> _VG.run()
