clear all
close all
clc
%% Design Choices
Design_Choice.Freq= 90e9; %Must be in Hz
Design_Choice.Alt = 3.5e3; %Must be in meters
Design_Choice.Graze_Bore = [19]; %degrees
Design_Choice.Ant_Dia.El = 0.4; %meters
Design_Choice.Ant_Dia.Az = 0.25; %meters
Design_Choice.Spin_Rate = 0; %rpm
Design_Choice.Swath_Beta = 55; %+./- deg
Design_Choice.Xmtr_Pwr = 640; %Watts
Design_Choice.Xmt_Tau = 0.095e-6; %seconds
Design_Choice.PRF = 0; %This will be a scaled down version of max
Design_Choice.Tfa = 0; %seconds
Design_Choice.Num_Scans_on_Target = 7;
% Design_Choice.PCR = 0;
% Design_Choice.Detection_to_Doppler = 0;

%% Fixed Input Parameters
Fixed.UAV_Ground_Speed = 31.9; %m./s
Fixed.Airboat_Speed.Max = (170e3)./(60.*60); %170km./hr to m./s
Fixed.Airboat_Speed.Min = (50e3)./(60.*60); %170km./hr to m./s
Dist_Vec = {'Far','Bore', 'Near'};
Fixed.Tsys = func_Determine_Tsys(Design_Choice.Freq);
Fixed.Trials = 3;
Fixed.Successes = 2;


%% Derive Lambda
Derived.Lambda = func_Derive_Lambda(Design_Choice.Freq);

%% Derive HPBW Angles and 2-Way Pattern Angles
Derived.HPBW.Az = func_Derive_HPBW_Ang(Derived.Lambda, Design_Choice.Ant_Dia.Az);
Derived.HPBW.El = func_Derive_HPBW_Ang(Derived.Lambda, Design_Choice.Ant_Dia.El);

Derived.Ant_2_Way.Az = Derived.HPBW.Az./2;
Derived.Ant_2_Way.El = Derived.HPBW.El./2;

%% Derive Grazing Angles
Derived.Graze.Bore = Design_Choice.Graze_Bore;
[Derived.Graze.Near, Derived.Graze.Far] = func_Derive_Graze(Design_Choice.Graze_Bore, Derived.Ant_2_Way.El);

%% Derive 1 Way antenna gain
Derived.Ant_Gain_dB = func_Derive_Ant_Gain(Derived.HPBW.Az, Derived.HPBW.El);

%% Derive Xmtr Duty Cycle
Derived.Xmtr_DC = func_Derive_Xmtr_DC(Design_Choice.PRF, Design_Choice.Xmt_Tau);
%%%%%%%%%%%%%%%%%%%%%%% MAY NEED TO UPDATE TO INCLUDE DOPPLER ANALYSIS TOO

%% Derive Ranges
for Indx_Range = 1:numel(Dist_Vec)
    Derived.Range.(Dist_Vec{Indx_Range}) = func_Derive_Range(Design_Choice.Alt, Derived.Graze.(char(Dist_Vec(Indx_Range))));
end
%% Check for valid PRF
Max_PRF = 1./((Derived.Range.Far - Derived.Range.Near)./3e8 + 2*Design_Choice.Xmt_Tau);
if(Max_PRF < 500e3)
    Design_Choice.PRF = Max_PRF*0.95;
else
    Design_Choice.PRF = 499e3;
end
%% Check for valid Spin Rate
Derived.Length_Footprint = Design_Choice.Alt*(tand(90-Derived.Graze.Far) - tand(90-Derived.Graze.Near));
Period = (Derived.Length_Footprint/Design_Choice.Num_Scans_on_Target)./(Fixed.UAV_Ground_Speed + Fixed.Airboat_Speed.Max.*cosd(0));%cosd(Design_Choice.Swath_Beta));
Derived.Min_Spin = 60./Period;

Design_Choice.Spin_Rate = Derived.Min_Spin*1.05;


%% Derive Swath Width at Range Near
Derived.Swath_Width = func_Derive_Swath_Width(Design_Choice.Swath_Beta, Derived.Range.Near, Derived.Graze.Near);

%% Derive Pulse IFOV and dAz
for Indx_Range = 1:numel(Dist_Vec)
    [Derived.Pulse_IFOV.dR.(Dist_Vec{Indx_Range}), Derived.Pulse_IFOV.dAz.(Dist_Vec{Indx_Range})] = func_Derive_d_r_d_az(...
        Derived.Range.(Dist_Vec{Indx_Range}), Derived.Ant_2_Way.Az, Design_Choice.Xmt_Tau, Derived.Graze.(Dist_Vec{Indx_Range}));
end

%% Derive Tfa
Derived.Tfa = func_Derive_Tfa(Design_Choice.Spin_Rate);

%% Derive Atmospheric Loss
for Indx_Range = 1:numel(Dist_Vec)
    Derived.Path_Loss.(Dist_Vec{Indx_Range}) = func_Derive_Atom_Path_Loss(Design_Choice.Freq, Derived.Range.(Dist_Vec{Indx_Range}), Derived.Graze.(Dist_Vec{Indx_Range}));
end

%% Derive POT and TOT
[Derived.POT, Derived.TOT] = func_Derive_POT_TOT(Design_Choice.Spin_Rate, Derived.Ant_2_Way.Az, Design_Choice.PRF);

%% Derive Twarn and Dmin
[Derived.Twarn, Derived.Dmin] = Derive_Min_Warn_Time(Design_Choice.Alt, Derived.Graze.Near, Fixed.UAV_Ground_Speed, Fixed.Airboat_Speed.Max, Design_Choice.Swath_Beta);

%% Derive Noise Power in dB
Derived.Xmtr_BW = 1./Design_Choice.Xmt_Tau;
Derived.Noise_Power_dB = func_Derive_Noise_Power(Derived.Xmtr_BW, Fixed.Tsys);

%% Derive Target RCS
for Indx_Range = 1:numel(Dist_Vec)
    Derived.Target_RCS.(Dist_Vec{Indx_Range}) = func_Derive_Target_RCS(Derived.Graze.(Dist_Vec{Indx_Range}));
end

%% Derive Target Power Recieved
%Assumes losses are alreaedy negative and dB
for Indx_Range = 1:numel(Dist_Vec)
    [Derived.Power_Recieved.(Dist_Vec{Indx_Range}), Derived.X_Factor] = func_Derive_Power_Recieved(Design_Choice.Xmtr_Pwr,...
        Derived.Ant_Gain_dB, Derived.Lambda, Derived.Range.(Dist_Vec{Indx_Range}), Derived.Target_RCS.(Dist_Vec{Indx_Range}), Derived.Path_Loss.(Dist_Vec{Indx_Range}));
end

%% Derive Clutter Singla 0

for Indx_Range = 1:numel(Dist_Vec)
  Derived.Clutter_Sig_0.(Dist_Vec{Indx_Range}) = func_Derive_Clutter_Sig_0(Derived.Graze.(Dist_Vec{Indx_Range}));
end

%% Derive Clutter Power (C) and RCS
for Indx_Range = 1:numel(Dist_Vec)
    [Derived.Clutter_Power.(Dist_Vec{Indx_Range}), Derived.Clutter_RCS.(Dist_Vec{Indx_Range})] = func_Derive_Clutter_Power(Derived.X_Factor, Derived.Clutter_Sig_0.(Dist_Vec{Indx_Range}), Derived.Pulse_IFOV.dR.(Dist_Vec{Indx_Range}), Derived.Pulse_IFOV.dAz.(Dist_Vec{Indx_Range}), Derived.Range.(Dist_Vec{Indx_Range}));
end

%% Cumulative(2,3) Probability
Derived.Pfa = 1./(Derived.Tfa .* Derived.Xmtr_BW);

for Indx_Range = 1:numel(Dist_Vec)
    Derived.S_N_C.(Dist_Vec{Indx_Range}) = Derived.Power_Recieved.(Dist_Vec{Indx_Range}) - 10.*log10(10.^(Derived.Noise_Power_dB./10) + 10.^(Derived.Clutter_Power.(Dist_Vec{Indx_Range})./10));
    Derived.Pd_Single_Pulse.(Dist_Vec{Indx_Range}) = func_Prob_detection_improvement_alg(10.^(Derived.S_N_C.(Dist_Vec{Indx_Range})/10), Derived.Pfa, Derived.POT);
    Derived.Pd_2_3.(Dist_Vec{Indx_Range}) = func_Greater_Equal_Binom_CDF(Fixed.Successes, Fixed.Trials, Derived.Pd_Single_Pulse.(Dist_Vec{Indx_Range}));
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Doppler%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Analysis%%%%%%%%%%%%%%%%%%%%%%%%

%% Derive Doppler Measurement Percision
% Design_Choice.Num_Scans_on_Target = 1;
Derived.Dopp_Meas_Percision = func_Derive_Doppler_Measurement_Percision(Derived.Power_Recieved.Bore, Design_Choice.Xmt_Tau, Fixed.Tsys, Design_Choice.Num_Scans_on_Target, Derived.POT, Design_Choice.PRF);

%% Test Case 1
%Covers Doppler when target is 

Case1.Az0.Clutter = func_Derive_Dopp_Freq(Fixed.UAV_Ground_Speed, Derived.Graze.Bore, 0, Derived.Lambda);
Case1.Az0.Target = func_Derive_Dopp_Freq(Fixed.Airboat_Speed.Max, Derived.Graze.Bore, 0, Derived.Lambda);

if(abs(Case1.Az0.Clutter - Case1.Az0.Target) < Derived.Dopp_Meas_Percision)
    disp('Doppler Percision BAD')
else
    disp('Doppler Percision GOOD')
end

Case1.pSwath.Target = func_Derive_Dopp_Freq(Fixed.UAV_Ground_Speed, Derived.Graze.Bore, Design_Choice.Swath_Beta, Derived.Lambda);
Case1.pSwath.Clutter = func_Derive_Dopp_Freq(Fixed.Airboat_Speed.Max, Derived.Graze.Bore, Design_Choice.Swath_Beta, Derived.Lambda);

if(abs(Case1.pSwath.Clutter - Case1.pSwath.Target) < Derived.Dopp_Meas_Percision)
    disp('Doppler Percision BAD')
else
    disp('Doppler Percision GOOD')
end

Case1.mSwath.Target = func_Derive_Dopp_Freq(Fixed.UAV_Ground_Speed, Derived.Graze.Bore, -Design_Choice.Swath_Beta, Derived.Lambda);
Case1.mSwath.Clutter = func_Derive_Dopp_Freq(Fixed.Airboat_Speed.Max, Derived.Graze.Bore, -Design_Choice.Swath_Beta, Derived.Lambda);

if(abs(Case1.mSwath.Clutter - Case1.mSwath.Target) < Derived.Dopp_Meas_Percision)
    disp('Doppler Percision BAD')
else
    disp('Doppler Percision GOOD')
end

func_Compliance_Check(Derived, Design_Choice)
func_Goal_Values(Derived, Design_Choice)

%% Functions

function Lambda = func_Derive_Lambda(Freq)
c = 3e8;
Lambda = c./Freq;
end

function HPBW = func_Derive_HPBW_Ang(Lambda, Ant_Dia)
HPBW = rad2deg(1.2.*Lambda./Ant_Dia);
end

function [Graze_Near, Graze_Far] = func_Derive_Graze(Graze_Bore, Two_Way_El)
Cone_Bore = 90 - Graze_Bore;
Graze_Near = 90 - (Cone_Bore - Two_Way_El./2);
Graze_Far = 90 - (Cone_Bore + Two_Way_El./2);
end

function Ant_Gain_dB = func_Derive_Ant_Gain(HPBW_Az, HPBW_El)
Ant_Gain = 0.6.*4.*pi./(deg2rad(HPBW_Az) .* deg2rad(HPBW_El));
Ant_Gain_dB = 10.*log10(Ant_Gain);
end

function DC = func_Derive_Xmtr_DC(PRF, Xmt_Tau)
DC = Xmt_Tau .* PRF; % Same as Xmt_Tau./IPP since IPP = 1./PRF
end

function Swath_Width = func_Derive_Swath_Width(Radar_Swath_Az, Range_Near, Graze_Near)
Swath_Width = 2 .* cosd(Graze_Near).*Range_Near.*sind(Radar_Swath_Az);
end

function Range = func_Derive_Range(Alt, Graze)
Range = Alt./sind(Graze);
end

function [d_r, d_az] = func_Derive_d_r_d_az(Range, beta_az_deg, xmtr_PW, graze_ang_deg)
c = 3e8;
d_r = c.*xmtr_PW./(2.*cosd(graze_ang_deg));
d_az = Range.*deg2rad(beta_az_deg);
end

function Tfa = func_Derive_Tfa(Ant_RPM)
T_Spin = 60./Ant_RPM;
Tfa = 10.*T_Spin;
end

function Path_Loss = func_Derive_Atom_Path_Loss(Freq, Range, Graze)
Max_Atten_Range = 5e3./sind(Graze);

for ii = 1:numel(Range)
    if(Range(ii) > Max_Atten_Range(ii))
        Range = Max_Atten_Range;
    end
end
switch Freq
    case 37e9
        Path_Loss = -0.05.*(Range./1e3);
    case 90e9
        Path_Loss = -0.15.*(Range./1e3);
    case 150e9
        Path_Loss = -0.40.*(Range./1e3);
end
Path_Loss = 2*Path_Loss; %multiplied by two since it goes forward AND back
end

function Tsys = func_Determine_Tsys(Freq)

switch Freq
    case 37e9
        Tsys = 400;
    case 90e9
        Tsys = 500;
    case 150e9
        Tsys = 700;
end

end

function Noise_Pwr_dB = func_Derive_Noise_Power(Xmtr_BW, Tsys)
k = 1.38e-23;

Noise_Pwr = k.*Tsys.*Xmtr_BW;
Noise_Pwr_dB = 10.*log10(Noise_Pwr);

end

function [Pr, X_Factor] = func_Derive_Power_Recieved(Pt, Gain, Lambda, Range, Target_RCS, Losses)

X_Factor = 10.*log10(Pt) + 2.*Gain + 2.*10.*log10(Lambda)  + Losses - 3.*10.*log10(4.*pi);
Pr = X_Factor + 10.*log10(Target_RCS)- 4.*10.*log10(Range);
end

function RCS = func_Derive_Target_RCS(Graze_Ang)
P1 = -4.41228E-9;
P2 = 1.24415E-6;
P3 = -1.2775E-4;
P4 = 5.7724E-3;
P5 = -0.1075;
P6 = 0.5756;
P7 = 5.90;
RCS = P1.*(Graze_Ang).^6 + P2.*(Graze_Ang).^5 + P3.*(Graze_Ang).^4 + P4.*(Graze_Ang).^3 + P5.*(Graze_Ang).^2 + P6.*(Graze_Ang) + P7;
end

function [Clutter_Power_dB, Clutter_RCS] = func_Derive_Clutter_Power(X_factor,Clutter_Sig_0, d_R, d_Az, Range)
Clutter_RCS = d_R.*d_Az.*(10.^(Clutter_Sig_0./10));
Clutter_RCS_dB = 10.*log10(Clutter_RCS);
Clutter_Power_dB = X_factor + Clutter_RCS_dB - 4.*10.*log10(Range);
end

function [POT, TOT] = func_Derive_POT_TOT(Spin_Rate_RPM, Az_2_Way_deg, PRF)
TOT = (60./Spin_Rate_RPM) .* (Az_2_Way_deg./360);
POT = floor(PRF.*TOT); %POT must be an integer
end

function Clutt_Sig_0 = func_Derive_Clutter_Sig_0(Graze_Ang)
P1 = -4.3868E-6;
P2 = 0.00098614;
P3 = -0.071347;
P4 = 2.2443;
P5 = -44.959;
Clutt_Sig_0 = P1.*(Graze_Ang).^4 + P2.*(Graze_Ang).^3 + P3.*(Graze_Ang).^2 + P4.*(Graze_Ang) + P5;
end

function [Twar, Dmin] = Derive_Min_Warn_Time(Alt, Graze_Near, Vel_Plane, Vel_Target, Swath_Ang)
Dmin = Alt*tand(90 - Graze_Near);
Vel_Rel = Vel_Plane - Vel_Target*cosd(180);
Twar = Dmin/Vel_Rel;
Twar = cosd(Swath_Ang)*Twar; %may need to delete if wrong
end

function Dopp_Percision = func_Derive_Doppler_Measurement_Percision(Pr, Xmt_PW, Temp_Sys, Num_Scans, POT, PRF)

E = 10^(Pr/10)*Xmt_PW;
k = 1.38e-23;
N_0 = k*Temp_Sys;

TOT = Num_Scans.*(POT - 1)/PRF;

Dopp_Percision = 1/(TOT.*sqrt(2*E./N_0));

end

function Dopp_Freq = func_Derive_Dopp_Freq(V_Ac, Bore_Ang, Az_Ang, Lambda)

Dopp_Freq = 2*V_Ac*sind(Bore_Ang)*cosd(Az_Ang)/Lambda;

end
