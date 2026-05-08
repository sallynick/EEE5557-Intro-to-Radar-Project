function CDF_GE_Binom = func_Greater_Equal_Binom_CDF(Successes, Trials, Prob_Single)
% MATLAB and Excel return cumulative probaility for <= to the number of successes
% while in radar we want >= so this function calculates it


Less_Equal_Binom_CDF = binocdf(Successes, Trials, Prob_Single); %calculate <= binom cdf
Prob_exact_equal = binopdf(Successes, Trials, Prob_Single); %calculate prob exactly equal to # success

CDF_GE_Binom = 1 - Less_Equal_Binom_CDF; %calcualte > binom cdf
CDF_GE_Binom = CDF_GE_Binom + Prob_exact_equal; %add the = prob to get >= binom cdf


end