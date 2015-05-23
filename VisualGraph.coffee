_ = require('underscore')
$ = require('jquery')
d3 = require('d3-browserify')
algorithms = require('./algorithms.coffee')
VisualRunnerRange = require('visual-runner/range')

deepClone = (obj) ->
  if _.isArray(obj)
    _.map(obj, deepClone)
  else if _.isObject(obj)
    _.mapObject(obj, deepClone)
  else
    obj

class VisualGraph extends VisualRunnerRange
  constructor: ->
    @svg = d3.select('.js-svg')
    @force = @createForceLayout()

    @initParams = {}

    @exposedFuncs = {}
    @setupExposedFuncs()

    @setupEvents()
    @loadControls()

    @pauseButton = $("#js-pause")
    @playButton = $("#js-play")

    $select = $('#js-algorithms')
    for key, { name, text } of algorithms
      $select.append("<option value=\"#{ key }\">#{ name }</option>")

    @clearSavedState()

    super('VG')

  setupExposedFuncs: ->
    @exposedFuncs.getNodeCount = =>
      @data.nodes.length

    @exposedFuncs.getAdjacentNodes = (n) =>
      node = @data.nodes[n]
      _.chain(@data.links)
      .filter((link) -> link.source == node)
      .map((link) -> node: link.target.num, cost: link.cost)
      .value()

    @exposedFuncs.setCost = (source, target, newCost) =>
      sourceNode = @data.nodes[source]
      targetNode = @data.nodes[target]
      edge = _.find(@data.links, _.matcher(source: sourceNode, target: targetNode))
      if edge?
        edge.cost = newCost

    @exposedFuncs.addEdge = (source, target, cost) =>
      source = @data.nodes[source]
      target = @data.nodes[target]

      @data.links.push({ source, target, cost })

    @exposedFuncs.highlightEdge = (source, target, newColor="red") =>
      sourceNode = @data.nodes[source]
      targetNode = @data.nodes[target]
      edge = _.find(@data.links, _.matcher(source: sourceNode, target: targetNode))
      if edge?
        edge.color = newColor

    @exposedFuncs.unhighlightEdge = (source, target) =>
      sourceNode = @data.nodes[source]
      targetNode = @data.nodes[target]
      edge = _.find(@data.links, _.matcher(source: sourceNode, target: targetNode))
      if edge?
        edge.color = ""

    @exposedFuncs.highlightNode = (n, newColor="red") =>
      node = @data.nodes[n]
      if node?
        node.color = newColor

    @exposedFuncs.unhighlightNode = (n) =>
      node = @data.nodes[n]
      if node?
        node.color = ""

  setupEvents: ->
    $('#js-nodes-length').change(@onInitialChange.bind(@))
    $('#js-edges-length').change(@onInitialChange.bind(@))
    $('#js-show-edge-cost').change(@render.bind(@))
    $('#js-show-node-num').change(@render.bind(@))
    $('#js-run').on 'click', =>
      @run()
      $('#js-play').prop('disabled', false)
      return false
    $('#js-play').click =>
      @play()
      return false
    $('#js-pause').click =>
      @pause()
      return false
    $('#js-algorithms').change =>
      $('#js-code').text(algorithms[$('#js-algorithms').val()].text)
      return
    $("#js-speed").on 'input', =>
      speed = $("#js-speed").val()
      if isFinite speed
        @stepLength = 501 - +speed
      return
    @setupSeekControl($('#js-seek'))

  loadControls: ->
    @initParams.nodesLength = parseInt($("#js-nodes-length").val(), 10)
    @initParams.edgesLength = parseInt($("#js-edges-length").val(), 10)
    maxEdges = @initParams.nodesLength * @initParams.nodesLength
    if @initParams.edgesLength > maxEdges
      @initParams.edgesLength = maxEdges

  renderControls: ->
    $("#js-nodes-length").val(@initParams.nodesLength)
    $("#js-edges-length").val(@initParams.edgesLength)

  createForceLayout: ->
    d3.layout.force()
      .charge(-300)
      .linkDistance(200)
      .linkStrength(0.9)
      .size([800, 400])

  clearSavedState: ->
    @savedState = {}

  createInitialState: (key) ->
    nodeCount = @initParams.nodesLength
    linkCount = @initParams.edgesLength
    @savedState[key] =
      nodes: []
      links: []

    for i in [0...nodeCount]
      @savedState[key].nodes.push(num: i)

    for source in [0...nodeCount]
      for target in [0...nodeCount]
        @savedState[key].links.push({ source, target, cost: _.random(1, 100) })

    while @savedState[key].links.length > linkCount
      @savedState[key].links.splice(_.random(0, @savedState[key].links.length - 1), 1)

    @loadState(key)

    $("#js-pause").hide()
    $("#js-play").prop("disabled", true).show()

  saveState: (key) ->
    @savedState[key] = {}

    @savedState[key].nodes =
      for node in @data.nodes
        { num: node.num, color: node.color }

    @savedState[key].links =
      for link in @data.links
        { source: link.source.num, target: link.target.num, cost: link.cost, color: link.color }

  loadState: (key) ->
    oldData = @data
    @data = deepClone(@savedState[key])
    for link in @data.links
      link.source = @data.nodes[link.source]
      link.target = @data.nodes[link.target]

    for oldNode in oldData?.nodes ? []
      newNode = _.find(@data.nodes, _.matcher(num: oldNode.num))
      if newNode?
        _.extend(newNode, _.pick(oldNode, 'x', 'y', 'px', 'py'))

  doTask: ->
    code = $("#js-code").val()
    $("#js-error").hide()
    try
      CoffeeScript.eval(code)
    catch error
      $("#js-error").html(error.message).show()

  render: (data) ->
    # render locals
    $('#js-result').html('')
    for key, val of data.locals
      $('#js-result').append("#{ key }: #{ val }<br />")

    # render graph
    nodes = @data.nodes
    links = @data.links
    @force
      .nodes(nodes)
      .links(links)
      .start()

    $links = @svg.selectAll('.link').data(links)
    $links
      .enter()
      .insert('path')
      .attr "marker-end", (d) ->
        if d.source == d.target
          "url(#end-self)"
        else
          "url(#end)"
    $links
      .exit()
      .remove()
    $links
      .classed('link', true)
      .style('stroke', (d) -> d.color)

    if $("#js-show-edge-cost").prop("checked")
      $linkLabels = @svg.selectAll(".link-label").data(links)
      $linkLabels
        .enter()
        .insert('text')
        .attr("text-anchor", "middle")
        .classed('link-label', true)
      $linkLabels
        .exit()
        .remove()
    else
      @svg.selectAll('.link-label').remove()

    $gnodes = @svg.selectAll(".gnode").data(nodes)
    $newgnodes = $gnodes
      .enter()
      .insert('g')
      .classed('gnode', true)
    $gnodes
      .exit()
      .remove()

    $newgnodes
      .insert('circle')
      .classed('node', true)
      .attr('r', 10)

    $newgnodes
      .insert('text')
      .attr('y', 1)
    if $("#js-show-node-num").prop("checked")
      @svg.selectAll(".gnode text").text((d) -> d.num)
    else
      @svg.selectAll(".gnode text").text("")

    @svg.selectAll('.node').data(nodes)
      .style('fill', (d) => d.color)

    @force.on 'tick', =>
      @svg.selectAll('.link')
        .attr('d', (d) ->
          if d.source == d.target
            radius = 20
            "M#{d.source.x},#{d.source.y}A#{radius},#{radius} 0 0,1 #{d.source.x},#{d.source.y - radius * 2}A#{radius},#{radius} 0 0,1 #{d.source.x},#{d.source.y}"
          else
            dx = d.target.x - d.source.x
            dy = d.target.y - d.source.y
            dr = Math.sqrt(dx * dx + dy * dy) * 2
            "M#{ d.source.x },#{ d.source.y }A#{ dr },#{ dr } 0 0,1 #{ d.target.x },#{ d.target.y }"
        )

      @svg.selectAll('.link-label')
        .attr('transform', (d) ->
          if d.source == d.target
            x = d.source.x - 7
            y = d.source.y - 23
          else
            dx = d.target.x - d.source.x
            dy = d.target.y - d.source.y
            theta = -1 * Math.PI / 9
            cosTheta = Math.cos(theta)
            sinTheta = Math.sin(theta)
            newdx = dx * cosTheta - dy * sinTheta
            newdy = dx * sinTheta + dy * cosTheta
            x = (d.source.x * 2 + newdx) / 2
            y = (d.source.y * 2 + newdy) / 2 + 8
          "translate(#{ x },#{ y })"
        )
        .text((d) -> d.cost)

      @svg.selectAll('.gnode')
        .attr('transform', (d) -> "translate(#{d.x},#{d.y})")

# export the VisualGraph class.
module.exports = VisualGraph
