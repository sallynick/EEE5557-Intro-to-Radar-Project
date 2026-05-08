function func_Compliance_Check(Derived, Design_Choice)
Full_Comp = 0;

if(Derived.Swath_Width < 10e3)
    disp('Swath Width BAD')
    Full_Comp = 1;
end

if(Design_Choice.Ant_Dia.Az > 2)
    disp('AZ Ant Dia BAD')
    Full_Comp = 1;
end

if(Design_Choice.Ant_Dia.El > 2)
    disp('AZ Ant Dia BAD')
    Full_Comp = 1;
end

if(Derived.Graze.Far < 2)
    disp('Graze Far BAD')
    Full_Comp = 1;
end

if(Design_Choice.PRF > 500e3)
    disp('PRF BAD')
    Full_Comp = 1;
end

if(Derived.Tfa < 10)
    disp('Tfa BAD')
    Full_Comp = 1;
end

if((Design_Choice.Spin_Rate > 180) || (Design_Choice.Spin_Rate < Derived.Min_Spin))
    disp('Spin Rate BAD')
    Full_Comp = 1;
end

if(Design_Choice.Num_Scans_on_Target < 3)
    disp('Num_Scans_on_Target BAD')
    Full_Comp = 1;
end

if(Derived.Twarn < 6)
    disp('Twarn BAD')
    Full_Comp = 1;
end

if(Design_Choice.Xmtr_Pwr > 1.5e3)
    disp('Xmtr_Pwr BAD')
    Full_Comp = 1;
end


if(Derived.Xmtr_DC > 0.1005)
    disp('Xmtr_DC BAD')
    Full_Comp = 1;
end

if(Derived.Pulse_IFOV.dR.Bore < 6)
    disp('dR BAD')
    Full_Comp = 1;
end

if(Derived.Pulse_IFOV.dAz.Bore < 6)
    disp('dAz BAD')
    Full_Comp = 1;
end

if(Derived.Pd_2_3.Far < 0.8)
    disp('Pd BAD')
    Full_Comp = 1;
end

if(Derived.Dopp_Meas_Percision > 700)
    disp('Dopp_Meas_Percision BAD')
    Full_Comp = 1;
end

if(Full_Comp == 0)
    disp('Fully Compliant')
end


end