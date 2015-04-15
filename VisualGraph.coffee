_ = require('underscore')
$ = require('jquery')
d3 = require('d3-browserify')
VisualRunner = require('./VisualRunner.coffee')

deepClone = (obj) ->
  if _.isArray(obj)
    _.map(obj, deepClone)
  else if _.isObject(obj)
    _.mapObject(obj, deepClone)
  else
    obj

class VisualGraph extends VisualRunner
  constructor: ->
    @svg = d3.select('.js-svg')
    @force = @createForceLayout()

    @initParams = {}

    @exposedFuncs = {}
    @setupExposedFuncs()

    @setupEvents()
    @loadControls()

    super('VG')

  setupExposedFuncs: ->
    @exposedFuncs.getNodeLength = =>
      @data.nodes.length

    @exposedFuncs.getAdjacentNodes = (n) =>
      node = @data.nodes[n]
      _.chain(@data.links)
      .filter((link) -> link.source == node)
      .map((link) -> link.target.index)
      .value()

    @exposedFuncs.addEdge = (source, target) =>
      source = @data.nodes[source]
      target = @data.nodes[target]

      @data.links.push({ source, target })

    @exposedFuncs.highlightEdge = (source, target) =>
      sourceNode = @data.nodes[source]
      targetNode = @data.nodes[target]
      edge = _.find(@data.links, _.matcher(source: sourceNode, target: targetNode))
      if edge?
        edge.class = "highlight"

  setupEvents: ->
    $("#js-nodes-length").change(@onInitialChange.bind(@))
    $("#js-edges-length").change(@onInitialChange.bind(@))
    $("#js-show-edge-cost").change(@render.bind(@))
    $("#js-show-node-num").change(@render.bind(@))
    @setupSeekControl($("#js-seek"))

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
      .linkDistance(100)
      .size([800, 400])

  createInitialState: ->
    nodeCount = @initParams.nodesLength
    linkCount = @initParams.edgesLength
    @initData =
      nodes: []
      links: []

    for i in [0...nodeCount]
      @initData.nodes.push(num: i)

    for source in [0...nodeCount]
      for target in [0...nodeCount]
        @initData.links.push({ source, target, cost: _.random(1, 100) })

    while @initData.links.length > linkCount
      @initData.links.splice(_.random(0, @initData.links.length - 1), 1)

    @loadInitialState()

  loadInitialState: ->
    oldData = @data
    @data = deepClone(@initData)
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

  render: ->
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
      .attr("marker-end", "url(#end)")
    $links
      .exit()
      .remove()
    $links
      .attr('class', (d) -> _.compact(['link', d.class]).join(" "))

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
      .insert('text')
      .text((d) -> d.num)
      .attr('x', '7')
      .attr('y', '8')

    $newgnodes
      .insert('circle')
      .classed('node', true)
      .attr('r', 4)

    @force.on 'tick', =>
      @svg.selectAll('.link')
        .attr('d', (d) ->
          if d.source == d.target
            radius = 10
            "M#{d.source.x},#{d.source.y}A#{radius},#{radius} 0 0,0 #{d.source.x},#{d.source.y - radius * 2}A#{radius},#{radius} 0 0,0 #{d.source.x},#{d.source.y}"
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
