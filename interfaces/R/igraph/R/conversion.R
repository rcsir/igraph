
#   IGraph R package
#   Copyright (C) 2005-2012  Gabor Csardi <csardi.gabor@gmail.com>
#   334 Harvard street, Cambridge, MA 02139 USA
#   
#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 2 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#   
#   You should have received a copy of the GNU General Public License
#   along with this program; if not, write to the Free Software
#   Foundation, Inc.,  51 Franklin Street, Fifth Floor, Boston, MA
#   02110-1301 USA
#
###################################################################

get.adjacency.dense <- function(graph, type=c("both", "upper", "lower"),
                                attr=NULL, edges=FALSE, names=TRUE) {

  if (!is.igraph(graph)) {
    stop("Not a graph object")
  }
  
  type <- igraph.match.arg(type)
  type <- switch(type, "upper"=0, "lower"=1, "both"=2)
  
  if (edges || is.null(attr)) {    
    on.exit( .Call("R_igraph_finalizer", PACKAGE="igraph") )
    res <- .Call("R_igraph_get_adjacency", graph, as.numeric(type),
                 as.logical(edges), PACKAGE="igraph")
  } else {
    attr <- as.character(attr)
    if (! attr %in% list.edge.attributes(graph)) {
      stop("no such edge attribute")
    }
    exattr <- get.edge.attribute(graph, attr)
    if (is.logical(exattr)) {
      res <- matrix(FALSE, nrow=vcount(graph), ncol=vcount(graph))
    } else if (is.character(exattr)) {
      res <- matrix("", nrow=vcount(graph), ncol=vcount(graph))
    } else if (is.numeric(exattr)) {
      res <- matrix(0, nrow=vcount(graph), ncol=vcount(graph))
    } else {
      stop("Sparse matrices must be either numeric or logical,",
           "and the edge attribute is not")
    }
    if (is.directed(graph)) {
      for (i in seq(length=ecount(graph))) {
        e <- get.edge(graph, i)
        res[ e[1], e[2] ] <- get.edge.attribute(graph, attr, i)
      }
    } else {
      if (type==0) {
        ## upper
        for (i in seq(length=ecount(graph))) {
          e <- get.edge(graph, i)
          res[ min(e), max(e) ] <- get.edge.attribute(graph, attr, i)
        }        
      } else if (type==1) {
        ## lower
        for (i in seq(length=ecount(graph))) {
          e <- get.edge(graph, i)
          res[ max(e), min(e) ] <- get.edge.attribute(graph, attr, i)
        }        
      } else if (type==2) {
        ## both
        for (i in seq(length=ecount(graph))) {
          e <- get.edge(graph, i)
          res[ e[1], e[2] ] <- get.edge.attribute(graph, attr, i)
          if (e[1] != e[2]) {
            res[ e[2], e[1] ] <- get.edge.attribute(graph, attr, i)
          }
        }
      }
    }
  }

  if (names && "name" %in% list.vertex.attributes(graph)) {
    colnames(res) <- rownames(res) <- V(graph)$name
  }
  
  res  
}

get.adjacency.sparse <- function(graph, type=c("both", "upper", "lower"),
                                 attr=NULL, edges=FALSE, names=TRUE) {

  if (!is.igraph(graph)) {
    stop("Not a graph object")
  }

  type <- igraph.match.arg(type)

  vc <- vcount(graph)
  
  el <- get.edgelist(graph, names=FALSE)
  if (edges) {
    value <- seq_len(nrow(el))
  } else if (!is.null(attr)) {
    attr <- as.character(attr)
    if (!attr %in% list.edge.attributes(graph)) {
      stop("no such edge attribute")
    }
    value <- get.edge.attribute(graph, name=attr)
    if (!is.numeric(value) && !is.logical(value)) {
      stop("Sparse matrices must be either numeric or logical,",
           "and the edge attribute is not")
    }
  } else {
    value <- rep(1, nrow(el))
  }

  if (is.directed(graph)) {
    res <- Matrix::sparseMatrix(dims=c(vc, vc), i=el[,1], j=el[,2], x=value)
  } else {
    if (type=="upper") {
      ## upper
      res <- Matrix::sparseMatrix(dims=c(vc, vc), i=pmin(el[,1],el[,2]),
                          j=pmax(el[,1],el[,2]), x=value)
    } else if (type=="lower") {
      ## lower
      res <- Matrix::sparseMatrix(dims=c(vc, vc), i=pmax(el[,1],el[,2]),
                          j=pmin(el[,1],el[,2]), x=value)
    } else if (type=="both") {
      ## both
      res <- Matrix::sparseMatrix(dims=c(vc, vc), i=pmin(el[,1],el[,2]),
                          j=pmax(el[,1],el[,2]), x=value, symmetric=TRUE)
      res <- as(res, "dgCMatrix")
    }
  }

  if (names && "name" %in% list.vertex.attributes(graph)) {
    colnames(res) <- rownames(res) <- V(graph)$name
  }

  res
}

get.adjacency <- function(graph, type=c("both", "upper", "lower"),
                          attr=NULL, edges=FALSE, names=TRUE, 
                          sparse=getIgraphOpt("sparsematrices")) {
  if (!is.igraph(graph)) {
    stop("Not a graph object")
  }

  if (!sparse) {
    get.adjacency.dense(graph, type=type, attr=attr, edges=edges, names=names)
  } else {
    get.adjacency.sparse(graph, type=type, attr=attr, edges=edges, names=names)
  }  
}

get.edgelist <- function(graph, names=TRUE) {
  if (!is.igraph(graph)) {
    stop("Not a graph object")
  }
  on.exit( .Call("R_igraph_finalizer", PACKAGE="igraph") )
  res <- matrix(.Call("R_igraph_get_edgelist", graph, TRUE,
                      PACKAGE="igraph"), ncol=2)
  res <- res+1
  if (names && "name" %in% list.vertex.attributes(graph)) {
    res <- matrix(V(graph)$name[ res ], ncol=2)
  }

  res
}

as.directed <- function(graph, mode=c("mutual", "arbitrary")) {
  if (!is.igraph(graph)) {
    stop("Not a graph object")
  }

  mode <- igraph.match.arg(mode)
  mode <- switch(mode, "arbitrary"=0, "mutual"=1)
  
  on.exit( .Call("R_igraph_finalizer", PACKAGE="igraph") )
  .Call("R_igraph_to_directed", graph, as.numeric(mode),
        PACKAGE="igraph")
}

get.adjlist <- function(graph, mode=c("all", "out", "in", "total")) {
  if (!is.igraph(graph)) {
    stop("Not a graph object")
  }

  mode <- igraph.match.arg(mode)
  mode <- as.numeric(switch(mode, "out"=1, "in"=2, "all"=3, "total"=3))
  on.exit( .Call("R_igraph_finalizer", PACKAGE="igraph") )
  res <- .Call("R_igraph_get_adjlist", graph, mode,
               PACKAGE="igraph")
  res <- lapply(res, function(x) x+1)
  if (is.named(graph)) names(res) <- V(graph)$name
  res
}

get.adjedgelist <- function(graph, mode=c("all", "out", "in", "total")) {
  if (!is.igraph(graph)) {
    stop("Not a graph object")
  }

  mode <- igraph.match.arg(mode)
  mode <- as.numeric(switch(mode, "out"=1, "in"=2, "all"=3, "total"=3))
  on.exit( .Call("R_igraph_finalizer", PACKAGE="igraph") )
  res <- .Call("R_igraph_get_adjedgelist", graph, mode,
               PACKAGE="igraph")
  res <- lapply(res, function(x) x+1)
  if (is.named(graph)) names(res) <- V(graph)$name
  res
}

igraph.from.graphNEL <- function(graphNEL, name=TRUE, weight=TRUE,
                                 unlist.attrs=TRUE) {

  if (! "graph" %in% .packages()) {
    library(graph, pos="package:base")
  }

  if (!inherits(graphNEL, "graphNEL")) {
    stop("Not a graphNEL graph")
  }
  
  al <- lapply(edgeL(graphNEL), "[[", "edges")
  if (edgemode(graphNEL)=="undirected") {
    al <- mapply(SIMPLIFY=FALSE, seq_along(al), al, FUN=function(n, l) {
      c(l, rep(n, sum(l==n)))
    })
  }
  mode <- if (edgemode(graphNEL)=="directed") "out" else "all"
  g <- graph.adjlist(al, mode=mode, duplicate=TRUE)
  if (name) {
    V(g)$name <- nodes(graphNEL)
  }

  ## Graph attributes
  g.n <- names(graphNEL@graphData)
  g.n <- g.n [ g.n != "edgemode" ]
  for (n in g.n) {
    g <- set.graph.attribute(g, n, graphNEL@graphData[[n]])
  }
  
  ## Vertex attributes
  v.n <- names(nodeDataDefaults(graphNEL))
  for (n in v.n) {
    val <- unname(nodeData(graphNEL, attr=n))
    if (unlist.attrs && all(sapply(val, length)==1)) { val <- unlist(val) }
    g <- set.vertex.attribute(g, n, value=val)
  }

  ## Edge attributes
  e.n <- names(edgeDataDefaults(graphNEL))
  if (!weight) { e.n <- e.n [ e.n != "weight" ] }
  if (length(e.n) > 0) {
    el <- get.edgelist(g)
    el <- paste(sep="|", el[,1], el[,2])
    for (n in e.n) {
      val <- unname(edgeData(graphNEL, attr=n)[el])
      if (unlist.attrs && all(sapply(val, length)==1)) { val <- unlist(val) }
      g <- set.edge.attribute(g, n, value=val)
    }
  }
  
  g 
}

igraph.to.graphNEL <- function(graph) {

  if (!is.igraph(graph)) {
    stop("Not an igraph graph")
  }
  
  if (! "graph" %in% .packages()) {
    library(graph, pos="package:base")
  }

  if ("name" %in% list.vertex.attributes(graph) &&
      is.character(V(graph)$name)) {
    name <- V(graph)$name
  } else {
    name <- as.character(seq(vcount(graph)))    
  }

  edgemode <- if (is.directed(graph)) "directed" else "undirected"  

  if ("weight" %in% list.edge.attributes(graph) &&
      is.numeric(E(graph)$weight)) {
    al <- get.adjedgelist(graph, "out")
    for (i in seq(along=al)) {
      edges <- get.edges(graph, al[[i]])
      edges <- ifelse( edges[,2]==i, edges[,1], edges[,2])
      weights <- E(graph)$weight[al[[i]]]
      al[[i]] <- list(edges=edges, weights=weights)
    }
  } else {
    al <- get.adjlist(graph, "out")
    al <- lapply(al, function(x) list(edges=x))
  }  
  
  names(al) <- name
  res <- new("graphNEL", nodes=name, edgeL=al, edgemode=edgemode)

  ## Add graph attributes (other than 'directed')
  ## Are this "officially" supported at all?

  g.n <- list.graph.attributes(graph)
  if ("directed" %in% g.n) {
    warning("Cannot add graph attribute `directed'")
    g.n <- g.n[ g.n != "directed" ]
  }
  for (n in g.n) {
    res@graphData[[n]] <- get.graph.attribute(graph, n)
  }

  ## Add vertex attributes (other than 'name', that is already
  ## added as vertex names)
  
  v.n <- list.vertex.attributes(graph)
  v.n <- v.n[ v.n != "name" ]
  for (n in v.n) {
    nodeDataDefaults(res, attr=n) <- NA
    nodeData(res, attr=n) <- get.vertex.attribute(graph, n)
  }

  ## Add edge attributes (other than 'weight')
  
  e.n <- list.edge.attributes(graph)
  e.n <- e.n[ e.n != "weight" ]
  if (length(e.n) > 0) {
    el <- get.edgelist(graph)
    el <- paste(sep="|", el[,1], el[,2])
    for (n in e.n) {
      edgeDataDefaults(res, attr=n) <- NA
      res@edgeData@data[el] <- mapply(function(x,y) {
        xx <- c(x,y); names(xx)[length(xx)] <- n; xx },
                                      res@edgeData@data[el],
                                      get.edge.attribute(graph, n),
                                      SIMPLIFY=FALSE)
    }
  }
  
  res
}

get.incidence.dense <- function(graph, types, names, attr) {

  if (is.null(attr)) {
    on.exit( .Call("R_igraph_finalizer", PACKAGE="igraph") )
    ## Function call
    res <- .Call("R_igraph_get_incidence", graph, types,
                 PACKAGE="igraph")

    if (names && "name" %in% list.vertex.attributes(graph)) {
      rownames(res$res) <- V(graph)$name[ res$row_ids+1 ]
      colnames(res$res) <- V(graph)$name[ res$col_ids+1 ]
    } else {
      rownames(res$res) <- res$row_ids+1
      colnames(res$res) <- res$col_ids+1
    }
    res$res
    
  } else {

    attr <- as.character(attr)
    if (!attr %in% list.edge.attributes(graph)) {
      stop("no such edge attribute")
    }

    vc <- vcount(graph)
    n1 <- sum(!types)
    n2 <- vc-n1    
    res <- matrix(0, n1, n2)

    recode <- numeric(vc)
    recode[!types] <- seq_len(n1)
    recode[types]  <- seq_len(n2)
    
    for (i in seq(length=ecount(graph))) {
      eo <- get.edge(graph, i)
      e <- recode[eo]
      if (!types[eo[1]]) {
        res[ e[1], e[2] ] <- get.edge.attribute(graph, attr, i)
      } else{
        res[ e[2], e[1] ] <- get.edge.attribute(graph, attr, i)
      }
    }

    if (names && "name" %in% list.vertex.attributes(graph)) {
      rownames(res) <- V(graph)$name[ which(!types) ]
      colnames(res) <- V(graph)$name[ which( types) ]
    } else {
      rownames(res) <- which(!types)
      colnames(res) <- which(types)
    }

    res
  }
}

get.incidence.sparse <- function(graph, types, names, attr) {

  vc <- vcount(graph)
  if (length(types) != vc) {
    stop("Invalid types vector")
  }

  el <- get.edgelist(graph, names=FALSE)
  if (any(types[el[,1]] == types[el[,2]])) {
    stop("Invalid types vector, not a bipartite graph")
  }

  n1 <- sum(!types)
  n2 <- vc-n1

  recode <- numeric(vc)
  recode[!types] <- seq_len(n1)
  recode[types]  <- seq_len(n2) + n1

  el[,1] <- recode[el[,1]]
  el[,2] <- recode[el[,2]]

  change <- el[,1] > n1
  el[change,] <- el[change,2:1]
  el[,2] <- el[,2]-n1

  if (!is.null(attr)) {
    attr <- as.character(attr)
    if (!attr %in% list.edge.attributes(graph)) {
      stop("no such edge attribute")
    }
    value <- get.edge.attribute(graph, name=attr)
  } else { 
    value <- rep(1, nrow(el))
  }

  res <- Matrix::spMatrix(n1, n2, i=el[,1], j=el[,2], x=value)

  if (names && "name" %in% list.vertex.attributes(graph)) {
    rownames(res) <- V(graph)$name[which(!types)]
    colnames(res) <- V(graph)$name[which(types)]
  } else {
    rownames(res) <- which(!types)
    colnames(res) <- which(types)
  }
  res
}

get.incidence <- function(graph, types=NULL, attr=NULL,
                          names=TRUE, sparse=FALSE) {
  # Argument checks
  if (!is.igraph(graph)) { stop("Not a graph object") }
  if (is.null(types) && "type" %in% list.vertex.attributes(graph)) { 
    types <- V(graph)$type 
  } 
  if (!is.null(types)) { 
    types <- as.logical(types) 
  } else { 
    stop("Not a bipartite graph, supply `types' argument") 
  }
  
  names <- as.logical(names)
  sparse <- as.logical(sparse)
  
  if (sparse) {
    get.incidence.sparse(graph, types=types, names=names, attr=attr)
  } else {
    get.incidence.dense(graph, types=types, names=names, attr=attr)
  }
}

get.data.frame <- function(x, what=c("edges", "vertices", "both")) {

  if (!is.igraph(x)) { stop("Not a graph object") }
  what <- igraph.match.arg(what)

  if (what %in% c("vertices", "both")) {
    ver <- .Call("R_igraph_mybracket2", x, 9L, 3L, PACKAGE="igraph")
    class(ver) <- "data.frame"
    rn <- if (is.named(x)) { V(x)$name } else { seq_len(vcount(x)) }
    rownames(ver) <- rn
  }

  if (what %in% c("edges", "both")) {
    el <- get.edgelist(x)
    edg <- c(list(from=el[,1]), list(to=el[,2]),
             .Call("R_igraph_mybracket2", x, 9L, 4L, PACKAGE="igraph"))
    class(edg) <- "data.frame"
    rownames(edg) <- seq_len(ecount(x))
  }
  
  if (what=="both") {
    list(vertices=ver, edges=edg)
  } else if (what=="vertices") {
    ver
  } else {
    edg
  }
}
