$("#js-stop").hide()

$(document).ready ->
  window.svg = d3.select('.js-svg')
  force = d3.layout.force()
    .charge(-120)
    .linkDistance(30)
    .size([800, 200])

  window.nodes = [{ name: 'hey', group: 0 }, { name: 'there', group: 1 }]
  window.links = [{ source: 0, target: 1 }]

  force
    .nodes(nodes)
    .links(links)
    .start()

  $links = svg.selectAll(".link")
    .data(links)
    .enter()
    .append('line')
    .classed('link', true)
    .attr("marker-end", "url(#end)")

  $gnodes = svg.selectAll("g.gnode")
    .data(nodes)
    .enter()
    .append('g')
    .classed('gnode', true)

  $gnodes
    .append('text')
    .text((d) -> d.name)
    .attr('x', '7')
    .attr('y', '8')

  $nodes = $gnodes
    .append('circle')
    .classed('node', true)
    .attr('r', 4)

  force.on 'tick', ->
    $links
      .attr('x1', (d) -> d.source.x)
      .attr('y1', (d) -> d.source.y)
      .attr('x2', (d) -> d.target.x)
      .attr('y2', (d) -> d.target.y)

    $gnodes
      .attr('transform', (d) -> "translate(#{d.x},#{d.y})")
