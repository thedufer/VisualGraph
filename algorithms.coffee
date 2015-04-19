module.exports =
  blank: ""
  dijkstra: """nodes = ({ node: n, cost: Infinity } for n in [0...VG.getNodeCount()])
nodes[0].cost = 0
VG.highlightNode(0, "red") # start node
unvisited = nodes.slice()

while unvisited.length
  current = do ->
    minIndex = 0
    for node, i in unvisited
      if unvisited[minIndex].cost > node.cost
        minIndex = i
    unvisited.splice(minIndex, 1)[0]

  VG.highlightNode(current.node, "green")

  for adj in VG.getAdjacentNodes(current.node)
    VG.highlightEdge(current.node, adj.node, "green")
    if nodes[adj.node].cost > current.cost + adj.cost
      nodes[adj.node].cost = current.cost + adj.cost
    VG.unhighlightEdge(current.node, adj.node)

  if current.node == 0
    VG.highlightNode(current.node, "red")
  else
    VG.highlightNode(current.node, "orange")"""
