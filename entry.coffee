$ = require('jquery')
VisualGraph = require('./VisualGraph.coffee')

$(document).ready ->
  window._VG = new VisualGraph()
  window.$ = $
  window.d3 = require('d3-browserify')
