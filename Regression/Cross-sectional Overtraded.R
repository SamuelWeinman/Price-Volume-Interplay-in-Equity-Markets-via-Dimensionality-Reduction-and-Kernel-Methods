
#FOR EACH DAY IN THE HISTORY (H), DECOMPOSES THE VOLUMES IN "EIGENVOLUME" PORTFOLIOS, YIELDING RESIDUALS ("OVERTRADED")
#RESIDUALS ARE THEN MAPPED BY RESIDUAL -> EXP(ALPHA * RESIDUALS), AND RETURNS ARE THEN DIVIDED BY THIS AMOUNT.
#THEN PROCEEDS AS NORMAL WITH CS REGRESSION.

#NrPC.V: HOW MANY PC TO USE WHEN CONSTRUCTED "EIGENVOLUME-PORTFOLIOS", 
#I.E. WHENS STUDYING IF (STOCK,DAY) IS OVERTRADED.
# ALPHA: SCALING OF VOLUME RESIDUALS BEFORE TAKING EXPONENTIAL

Day.CS.Overtrade = function(Volume, Returns, t, H, NrPC.V, NrPC, alpha) {

  #STANDARDISE VOLUME: DISTRIBUTION OF VOLUME ON THE PRVIOUS H DAYS. I.E. NOT A ROLLING WINDOW APPROACH AS BEFORE! 
  #FOR ANY T, WILL COMPARE ALL THE HISTORY TO THE H DAYS BEFORE T.
  StandardVolume = Volume[,(t-H):(t-1)]/apply(Volume[,(t-H):(t-1)],1,sum)
  
  #CONSTRUCT "EIGENPORTFOLIO" OF VOLUME
  E.V=ExtractEigenPortfolio(StandardVolume, NrPC.V)
  
  #CALCULATE BY HOW MUCH IT'S STOCK IS OVERTRADED OVERTRADING
  #HERE Overtraded_{I,T} IS THE AMOUNT THAT STOCK I WAS OVERTRADED ON DAY T
  Overtraded = sapply(1:H, function(i) {
    y = StandardVolume[,i] #standardise volume on the day
    model = lm(y~E.V$EigenPortfolio) #regress on eigenportfolios
    return(model$residuals) #extract residuals
  })
  
  #EXPONENTIAL RESIDUALS
  Overtraded= exp(alpha*Overtraded)

  #CONSTRUCT WEIGHTED RETURN, PENALISING LARGE TRADING DAYS
  WeightedReturn = Returns[,(t-H):(t-1)]/Overtraded
  
  #NOW, PROCEED AS BEFORE (CS)#
  
  #CONSTRUCT EIGENPORTFOLIOS
  E = ExtractEigenPortfolio(WeightedReturn, NrPC = NrPC)
  
  #REGRESS WEIGHTED RETURNS ON EIGENPORTFOLIOS
  y = WeightedReturn[,H]
  model = lm(y ~ E$EigenPortfolio)
  Prediction = -model$residuals
  
  #RETURN
  return(Prediction)
}

#PERFORMS CS OVERTRADED ON INTERVAL [START,END]
CrossSectionRegression.OverTrade = function(Start, End, Volume, Returns, H, NrPC.V,alpha, NrPC) {
  
  #PREPARE CORES#
  
  #VARIABLES TO SEND TO CORES FROM GLOBAL ENVIRONMENT
  Globalvarlist = c("Day.CS.Overtrade", "ExtractEigenPortfolio",
                    "ConstructEigenPortfolios", 
                    "ConstructRho")
  
  #VARIABLES TO SEND TO CORES FROM FUNCTION ENVIRONMENT
  Localvarlist = c("Volume", "Returns", "H", "NrPC.V","alpha", "NrPC")
  
  
  #OPEN CORES AND TRANSFER
  cl = snow::makeCluster(detectCores()-1)
  snow::clusterExport(cl, Globalvarlist) 
  snow::clusterExport(cl, Localvarlist, envir = environment()) 
  
  
  #GET PREDICTION OVER THE WHOLE TIME PERIOD
  #ROWS CORRESPOND TO STOCKS
  #THE COLUMNS CORRESPOND TO DAYS IN [START:END]
  Predictions=snow::parSapply(cl, Start:End, function(t) {
    Day.CS.Overtrade(Volume=Volume, Returns=Returns,
                     t=t, H=H,
                     NrPC.V=NrPC.V, NrPC=NrPC,
                     alpha=alpha)
  }) 
  
  #CLOSE CLUSTERS
  snow::stopCluster(cl)
  
  #CHANGE COL AND ROWNAMES AS APPROPRIATE.
  colnames(Predictions) = Start:End
  rownames(Predictions) = rownames(Returns)
  
  #RETURNS
  return(Predictions) 
}
  





