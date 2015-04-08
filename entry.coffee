$ = require('jquery')
VisualGraph = require('./VisualGraph.coffee')

$("#js-stop").hide()

$(document).ready ->
  window.VG = new VisualGraph()
