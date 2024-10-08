
###DECOMPOSE RETURNS INTO TWO PARTS:
# 1. DEPENDING ON THE RETURNS OF EIGENPORTFOLIOS
# 2. INDEPENDENT OF EIGENPORTFOLIOS
#  RETURNS: RETURN MATRIX TO CONSTRUCT RHO (FULL HISTORY UP TO TIME T-1)
#  H (history): NR OF DAYS TO USE TO CONSTRUCT CORRELATION MATRIX
#  L: NR OF DAYS TO USE FOR REGRESSION MODEL (NOT NECESSARILY SAME AS NR OF DAYS FOR CONSTRUCTING RHO, I.E. NCOL(RETURNSSHORT))
#  NrPC: AS ABOVE, FOR EIGENDECOMPOSITION.

Decomposition <- function(Returns, NrPC,H,L) {
  
  #DIMENSIONS
  N = nrow(Returns) #NR STOCKS
  
  #CONSTRUCT SHORT RETURN MATRIX USING ONLY LAST H DAYS
  ReturnsShort=Returns[,(ncol(Returns)-H+1):ncol(Returns)] #use last H days
  
  #EXTRACT EIGENPORTFOLIO ON SHORTER MATRIX
  Eigen = ExtractEigenPortfolio(ReturnsShort,NrPC) 
  
  #PERFORM REGRESSION
  #THE i:TH ENTRY IN MODELS IS THE REGRESSION OF THE i:TH STOCK ON THE EIGENPORTFOLIOS
  #NOTE THAT ReturnsShort AND Eigen$EigenReturn HAVE H COLUMNS
  Models <- lapply(1:N, function(i) { #loop through all stocks
    y = ReturnsShort[i,(H-L+1):H] #returns last L days
    X = Eigen$EigenReturn[,(H-L+1):H] #eigenreturns last L days
    model = lm(as.numeric(y)~t(as.matrix(X))) #get lm
    return(model)
  })
  
  #RETURN MODELS
  print(paste("Variability explained:", Eigen$PropExplained ))
  return(Models)
}


###ESTIMATE THE COEFFICIENTS OF THE UHRNBECK MODEL, FOR EACH STOCK SEPRATELY
#MODELS: MODELS OF THE FORM (RETURNS ~ FACTORS)
#FOLLOWS SAME ALGORITHM AS APPENDIX A OF Marco Avellaneda & Jeong-Hyun Lee (2010)
#IF B CLOSE TOO ONE, THERE IS NO MEAN REVERSION
#HENCE, REJECT MEAN REVERSION IF b > 1-bSensativity
EstimateCoefficeients <- function(Models, bSensativity) {
  
  #DIMENSIONS
  N=length(Models) #NR STOCKS
  L = length(Models[[1]]$residuals) #NR DAYS USED FOR MODEL
  
  #FOR EACH MODEL, ESTIMATE COEFFICIENTS
  #IN PARTICULAR, WE LOOP THROUGH EACH MODEL AND WITHIN EACH MODEL REGRESS THE CUMSUM OF THE RESIDUALS
  #EACH VECTOR X IS OF LENGTH L
  Coefficients <- lapply(1:N, function(i){
    X = cumsum(Models[[i]]$residuals) #cumsum residuals
    XModel = lm(X[2:L] ~ X[1:(L-1)]) #cumsum model
    a=as.numeric(XModel$coefficients[1]) #intercept 
    b=as.numeric(XModel$coefficients[2]) #coefficient (on X_{t-1})
    V = as.numeric(var(XModel$residuals)) #estimated variance
    
    #ESTIMATES
    k=-log(b)*252
    m= a/(1-b)
    Sigma.Squared= V * 2*k / (1-b^2)
    SigmaEq.Squared = V/ (1-b^2)
    
    #DECIDE IF THERE IS MEAN REVERSION
    MeanReversion = I(b< 1-bSensativity)
    
    #RETURN COEFFICIENTS FOR MODEL
    return(c(k,m,Sigma.Squared,SigmaEq.Squared, MeanReversion)) })
  
  #UPON CALCULATING COEFFICIENTS FOR EACH MODEL, PUT IN DATA FRAME
  Coefficients = ldply(Coefficients) #DATA FRAME
  colnames(Coefficients) = c("K", "m", "Sigma.Squared", "SigmaEq.Squared", "MeanReversion")
  #RETURN
  return(Coefficients)
}


###CALCULATE S-SCORE FOR ALL STOCKS AS IN Marco Avellaneda & Jeong-Hyun Lee (2010)
###THAT IS, THE AMOUNT BY WHICH THE STOCKS HAVE HAD TOO MUCH RETURNS
###IF MEAN-REVERSION==0, WE GIVE S=0 AS THERE IS NO MEAN REVERSION.
#RETURNS MUST BE HISTORY ONLY!
CalculatingS.Score <- function(Returns, NrPC,H,L,bSensativity) {

  #DECOMPOSE INTO MODELS
  Models=Decomposition(Returns=Returns,
                       H=H,
                       L=L,
                       NrPC=NrPC)

  
  #OBTAIN COEFFICIENTS FROM ABOVE MODELS
  Coefficients = EstimateCoefficeients(Models, bSensativity = bSensativity)
  
  #GET S-SCORE, USING METHODOLOGY IN APPENDIX
  #IF THERE IS NO MEAN-REVERSION, GIVE ZERO.
  #FIRST CREATE ARRAY, THEN GET S-SCORE FOR THOSE STOCKS WHERE THERE IS MEAN REVERSION
  S = numeric(nrow(Returns))
  index = Coefficients$MeanReversion==1 #mean reversion 
  S[index] = -Coefficients$m[index]/sqrt(Coefficients$SigmaEq.Squared[index]) #CORRESPONDING S-SCORE
  
  #RETURN
  return(list(
  S= S,
  MeanReversion = Coefficients$MeanReversion))
}




