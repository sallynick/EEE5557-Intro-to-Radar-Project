function Prob_detect = func_Prob_detection_improvement_alg(Sig_Noise, P_fa, n)

% Sig_Noise = 10.^(11.7096./10); %single pulse S./N expressed as power ratio (linear)
% P_fa = 7.8333e-10; % probability of false alarm
% n = 1; % # of pulse

A = log(0.62./P_fa);

epsilon = 1./(0.62 + 0.454./(sqrt(n + 0.44)));

chi = (Sig_Noise .* sqrt(n)).^(epsilon);

beta = (chi - A)./(0.12.*A + 1.7);

Prob_detect = (exp(beta))./(1+exp(beta)); %new prob detection w./ pulse integration

end