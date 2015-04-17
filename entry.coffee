$ = require('jquery')
VisualGraph = require('./VisualGraph.coffee')

$(document).ready ->
  $("#js-pause").hide()
  $("#js-play").prop("disabled", true)

  window._VG = new VisualGraph()
  window.$ = $
  window.d3 = require('d3-browserify')
