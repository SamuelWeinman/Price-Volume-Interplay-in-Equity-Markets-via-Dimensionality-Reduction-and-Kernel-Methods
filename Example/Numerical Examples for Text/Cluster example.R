library(stargazer)

t=4096 +252
H=252
alpha=0.5
k=4
MinSize=50

#CONSTRUCT WRIGHTED CORRELATION MATRIX
rho = alpha* ConstructRho(Returns[,(t-H):(t-1)]) + (1-alpha)*ConstructRho(Volume[,(t-H):(t-1)])

#CREATE CLUSTERS
Clusters = ConstructClusters(rho=rho, k=k, MinSize=MinSize)


#CALCULATE SIZE OF EACH CLUSTER
Sizes = sapply(1:4, function(i) length(Clusters[[i]]))

#EXTRACT 10 OF THE MOST TRADED IN EACH CLUSTER
Clusters.Short = data.frame(n=1)
for (i in 1:4) {
  Cluster = Clusters[[i]]
  Index = which(order(Volume[Cluster,t-1])<11)
  Companies = rownames(Returns)[Cluster[Index]]
  Clusters.Short= cbind(Clusters.Short,Companies)
}
Clusters.Short = Clusters.Short[,-1]
colnames(Clusters.Short) = "1:4"

stargazer(Clusters.Short, summary = FALSE)
