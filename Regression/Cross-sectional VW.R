library(snow)
library(parallel)

### THIS FUNCTION TRANSFORMS ALL RETURNS BY EITHER MULTIPLYING OR DIVIDING BY THE STANDARDISED VOLUME
#DIVIDE: IF TRUE, MULTIPLY BY MEAN(VOLUME)/VOLUME, ELSE MULTIPLY
#D: HOW MANY DAYS TO USE FOR STANDARDISING VOLUME
ConstructWeightedReturn = function(Returns, Volume,H,d,divide) {

  #CALCULATE THE ROLLING AVERAGE VOLUME 
  RollMeanVolume = t(roll_mean(t(as.matrix(Volume)), width = d))
  
  
  #WEIGHT RETURNS
  #EITHER MULTIPLY OR DIVIDE
  #NOTE THAT FOR DAYCROSSREGRESSION, THE INPUT CAN EITHER BE THE LAST H DAYS, OR MORE THAN THAT. IN THIS CASE, WE USE THE FULL HISTORY.
  if (divide==TRUE) {
    WeigthedReturn = Returns *  RollMeanVolume / Volume
  } #DIVIDE
  
  if (divide ==FALSE) {
    WeigthedReturn = Returns * Volume / RollMeanVolume 
  } #MULTIPLY
    
  
  #RETURN
  return(WeigthedReturn)
}

#PERFORMS CS VOLUME WEIGHTED IN INTERVAL [START,END], USING HISTORICAL DATA
#START: FIRST DAY OF TRADING
#END: LAST DAY OF TRADING
CrossSectionRegression.VW <- function(Returns, Volume, Start, End, H, NrPC,d,divide) {
  
  #CONSTRUCT WEIGHTED RETURN
  WeightedReturns = ConstructWeightedReturn(Returns=Returns, Volume=Volume,H=H,d=d,
                                            divide=divide)
  
  #PREPARE CORES#
  
  #VARIABLES TO SEND TO CORES FROM GLOBAL ENVIRONMENT
  Globalvarlist = c("DayCrossRegression","ConstructWeightedReturn",
                    "ExtractEigenPortfolio", "ConstructEigenPortfolios", 
                    "ConstructRho")
  
  #VARIABLES TO SEND TO CORES FROM FUNCTION ENVIRONMENT
  Localvarlist = c("WeightedReturns","H","NrPC")
  
  #OPEN CORES AND TRANSFER
  cl = snow::makeCluster(detectCores()-1)
  clusterCall(cl, function() library("roll"))
  snow::clusterExport(cl, Globalvarlist) 
  snow::clusterExport(cl, Localvarlist, envir = environment()) 
  
  #GET PREDICTION OVER THE WHOLE TIME PERIOD
  #ROWS CORRESPOND TO STOCKS
  #THE COLUMNS CORRESPOND TO DAYS IN [START:END]
  Predictions=snow::parSapply(cl, Start:End, function(t) {
    DayCrossRegression(Returns=WeightedReturns,
                       t=t,H=H,
                       NrPC=NrPC)
  }) 
  
  #CLOSE CLUSTERS
  snow::stopCluster(cl)
  
  #CHANGE COL AND ROWNAMES AS APPROPRIATE.
  colnames(Predictions) = Start:End
  rownames(Predictions) = rownames(Returns)
  
  #RETURN
  return(Predictions) 
}



#DOES CrossSectionRegression.VW, BUT AFTER A TRANSFORMATION OF VOLUME THROUGH MAPPING. 
# MAP.list: A LIST OF FUNCTIONS (F1,F2,...,FJ) S.T. VOLUME TRANSFORMED BY VOLUME -> F(VOLUME) BEFORE WEIGHTING.
Outside_CrossSectionRegression.VW = function(Returns, Volume, Start, End, H, NrPC,d,divide,MAP.list) {

  #NR OF MAPS
  K = length(MAP.list)
  
  #CREATE LIST TO STORE PREDICTIONS
  PredictionsList = list()
  
  #FOR EACH MAP, TRANSFORM VOLUME TO MAPPEDVOLUME AND THEN PROCEED WITH CS VW REGRESSION.
  for (k in 1:K) {
    map = MAP.list[[k]] #extract map
    MappedVolume = map(Volume) #map volume
    preds=CrossSectionRegression.VW(Returns=Returns,  #perform calculations with mapped volume
                                  Volume=MappedVolume,
                                  Start=Start, End=End, 
                                  H=H,
                                  NrPC=NrPC,
                                  d=d,
                                  divide=divide)
    PredictionsList[[k]]=preds #add to list
  }
  
  #RETURN
  return(PredictionsList)
}
