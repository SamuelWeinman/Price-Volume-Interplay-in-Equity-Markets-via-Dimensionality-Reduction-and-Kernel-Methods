Predictions.CT.Combined = CombinePrediction(PredictionStrong= Prediction.CT.KPCA,
                                            PredictionsWeak = Predictions.CT.OverTraded,
                                            alpha=0.4)


Scores.CT.Combined = Analysis(Returns,
                              Predictions = Predictions.CT.Combined,
                              r=30, Q=(1:4)/4)


SharpePPT.CT.Combined = CreatePlot.SharpePPT(Scores = list(Scores.CT, Scores.CT.KPCA, Scores.CT.OverTraded, Scores.CT.Combined),
                                             Labels = c("CT", "CT KPCA (Laplacian)", "CT Decomposed Volume", "CT Combined"),
                                             BaseModels = 1,
                                             Type="CT")



ggsave(filename = "SharpePPT.CT.Combined.png", 
       path = "C:\\Users\\Samuel Weinman\\OneDrive - Nexus365\\Documents\\MSc Statistical Science\\Dissertation\\Results\\Plots",
       plot = SharpePPT.CT.Combined,
       width = 5.8, height = 5)
