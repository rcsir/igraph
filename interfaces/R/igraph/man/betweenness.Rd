\name{betweenness}
\alias{betweenness}
\alias{edge.betweenness}
\alias{betweenness.estimate}
\alias{edge.betweenness.estimate}
\concept{Betweenness centrality}
\concept{Edge betweenness}
\title{Vertex and edge betweenness centrality}
\description{The vertex and edge betweenness are (roughly) defined by
  the number of geodesics (shortest paths) going through a vertex or an
  edge. 
}
\usage{
betweenness(graph, v=V(graph), directed = TRUE, weights = NULL,
     nobigint = TRUE, normalized = FALSE)
edge.betweenness(graph, e=E(graph), directed = TRUE, weights = NULL)
betweenness.estimate(graph, vids = V(graph), directed = TRUE, cutoff,
     weights = NULL, nobigint = TRUE)
edge.betweenness.estimate(graph, e=E(graph),
     directed = TRUE, cutoff, weights = NULL)
}
\arguments{
  \item{graph}{The graph to analyze.}
  \item{v}{The vertices for which the vertex betweenness will be
    calculated.}
  \item{e}{The edges for which the edge betweenness will be
    calculated.}
  \item{directed}{Logical, whether directed paths should be considered
    while determining the shortest paths.}
  \item{weights}{Optional positive weight vector for calculating
    weighted betweenness. If the graph has a \code{weight} edge
    attribute, then this is used by default.}
  \item{nobigint}{Logical scalar, whether to use big integers during the
    calculation. This is only required for lattice-like graphs that have
    very many shortest paths between a pair of vertices. If \code{TRUE}
    (the default), then big integers are not used.}
  \item{normalized}{Logical scalar, whether to normalize the betweenness
    scores. If \code{TRUE}, then the results are normalized according to
    \deqn{B^n=\frac{2B}{n^2-3n+2}}{Bnorm=2*B/(n*n-3*n+2)}, where
    \eqn{B^n}{Bnorm} is the normalized, \eqn{B} the raw betweenness, and
    \eqn{n} is the number of vertices in the graph.}
  \item{vids}{The vertices for which the vertex betweenness estimation
    will be calculated.}
  \item{cutoff}{The maximum path length to consider when calculating the
    betweenness. If zero or negative then there is no such limit.}
}
\details{The vertex betweenness of vertex \eqn{v}{\code{v}} is defined
  by

  \deqn{\sum_{i\ne j, i\ne v, j\ne v} g_{ivj}/g_{ij}}{sum( g_ivj / g_ij, i!=j,i!=v,j!=v)}
  
  The edge betweenness of edge \eqn{e}{\code{e}} is defined by

  \deqn{\sum_{i\ne j} g{iej}/g_{ij}.}{sum( g_iej / g_ij, i!=j).}

  \code{betweenness} calculates vertex betweenness,
  \code{edge.betweenness} calculates edge.betweenness.

  \code{betweenness.estimate} only considers paths of length
  \code{cutoff} or smaller, this can be run for larger graphs, as the
  running time is not quadratic (if \code{cutoff} is small). If
  \code{cutoff} is zero or negative then the function calculates the
  exact betweenness scores.

  \code{edge.betweenness.estimate} is similar, but for edges.

  For calculating the betweenness a similar algorithm to the one
  proposed by Brandes (see References) is used.
}
\value{A numeric vector with the betweenness score for each vertex in
  \code{v} for \code{betweenness}.

  A numeric vector with the edge betweenness score for each edge in
  \code{e} for \code{edge.betweenness}.

  \code{betweenness.estimate} returns the estimated betweenness scores
  for vertices in \code{vids}, \code{edge.betweenness.estimate}
  the estimated edge betweenness score for \emph{all} edges; both in
  a numeric vector.
}
\note{\code{edge.betweenness} might give false values for graphs with
  multiple edges.}
\references{Freeman, L.C. (1979). Centrality in Social Networks I:
  Conceptual Clarification. \emph{Social Networks}, 1, 215-239.

  Ulrik Brandes, A Faster Algorithm for Betweenness Centrality. \emph{Journal
  of Mathematical Sociology} 25(2):163-177, 2001. 
}
\author{Gabor Csardi \email{csardi.gabor@gmail.com}}
\seealso{\code{\link{closeness}}, \code{\link{degree}}}
\examples{
g <- random.graph.game(10, 3/10)
betweenness(g)
edge.betweenness(g)
}
\keyword{graphs}
