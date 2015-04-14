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
    @$links = @svg.selectAll(".link")
    @$gnodes = @svg.selectAll("g.gnode")

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
      .charge(-120)
      .linkDistance(50)
      .size([800, 400])

  createInitialState: ->
    nodeCount = @initParams.nodesLength
    linkCount = @initParams.edgesLength
    @initData =
      nodes: []
      links: []

    for i in [0...nodeCount]
      @initData.nodes.push(num: i)

    for i in [0...linkCount]
      @initData.links.push(source: _.random(nodeCount - 1), target: _.random(nodeCount - 1), cost: _.random(1, 100))

    @loadInitialState()

    force = @createForceLayout()
      .nodes(@data.nodes)
      .links(@data.links)
      .start()

    for x in [0...10]
      force.resume()
      while force.alpha() > 0
        force.tick()

    for [initNode, node] in _.zip(@initData.nodes, @data.nodes)
      initNode.x = node.x
      initNode.y = node.y

    @loadInitialState()

  loadInitialState: ->
    @data = deepClone(@initData)
    for link in @data.links
      link.source = @data.nodes[link.source]
      link.target = @data.nodes[link.target]

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

    @$links = @$links.data(links)
    @$links
      .enter()
      .insert('path')
      .attr("marker-end", "url(#end)")
    @$links
      .exit()
      .remove()
    @$links
      .attr('class', (d) -> _.compact(['link', d.class]).join(" "))

    @$gnodes = @$gnodes.data(nodes)
    @$gnodes
      .enter()
      .insert('g')
      .classed('gnode', true)
    @$gnodes
      .exit()
      .remove()

    @$gnodes
      .insert('text')
      .text((d) -> d.num)
      .attr('x', '7')
      .attr('y', '8')

    @$gnodes
      .insert('circle')
      .classed('node', true)
      .attr('r', 4)

    @force.on 'tick', =>
      @$links
        .attr('d', (d) ->
          if d.source == d.target
            radius = 10
            "M#{d.source.x},#{d.source.y}A#{radius},#{radius} 0 0,0 #{d.source.x},#{d.source.y - radius * 2}A#{radius},#{radius} 0 0,0 #{d.source.x},#{d.source.y}"
          else
            "M#{d.source.x},#{d.source.y}L#{d.target.x},#{d.target.y}"
        )

      @$gnodes
        .attr('transform', (d) -> "translate(#{d.x},#{d.y})")

# export the VisualGraph class.
module.exports = VisualGraph
