############### NEEDS TO BE DOUBLE CHECKED #################





d=20
t=4348
H=252
NrGroups = 10
col = which(colnames(Prediction.CS)==t)
NrPC.V = 25

preds = Prediction.CS.Overtraded[,col]


StandardVolume = Volume[,(t-H):(t-1)]/apply(Volume[,(t-H):(t-1)],1,sum)
E.V=ExtractEigenPortfolio(StandardVolume, NrPC.V)
Model = lm(StandardVolume[,H] ~ E.V$EigenPortfolio)
Overtraded = Model$residuals


Group.OT = as.factor(ceiling(order(Overtraded) / ceiling(659/NrGroups)))
Group.V = as.factor(ceiling(order(StandardVolume[,H]) / ceiling(659/NrGroups)))
data = data.frame(preds=preds, Group.OT=Group.OT, Group.V=Group.V)



ggplot(data, aes(x=Group.OT, y=preds)) + 
  geom_boxplot(fill="red") +
  ylab("Prediction") + xlab("Volume level")

ggplot(data, aes(x=Group.V, y=preds)) + 
  geom_boxplot(fill="red") +
  ylab("Prediction") + xlab("Volume level")





plot(tapply(Overtraded, Group.V, sd))
