_ = require('underscore')
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
    @force = d3.layout.force()
      .charge(-120)
      .linkDistance(50)
      .size([800, 400])
    @$links = @svg.selectAll(".link")
    @$gnodes = @svg.selectAll("g.gnode")

    @exposedFuncs = {}

    super('VG')

  createInitialState: ->
    nodeCount = 10
    linkCount = 20
    @initData =
      nodes: []
      links: []

    for i in [0...nodeCount]
      @initData.nodes.push(index: i, name: i.toString())

    for i in [0...linkCount]
      @initData.links.push(source: _.random(nodeCount - 1), target: _.random(nodeCount - 1))

    @loadInitialState()

  loadInitialState: ->
    @data = deepClone(@initData)
    for link in @data.links
      link.source = @data.nodes[link.source]
      link.target = @data.nodes[link.target]

  doTask: ->
    code = $("#js-code").val()
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
      .classed('link', true)
      .attr("marker-end", "url(#end)")
    @$links
      .exit()
      .remove()

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
      .text((d) -> d.name)
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
