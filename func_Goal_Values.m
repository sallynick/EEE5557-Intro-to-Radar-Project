function Goal_Total = func_Goal_Values(Derived, Design_Choice)

Ant_Dia_Spec = [0.1, 2]; %same for el and az
Spin_Num_Spec = [3 10];
Spin_Rate_Spec = [30 180];
Warn_Time_Spec = [6 60];
Dopp_Pre_Spec = [50 700];
Xmtr_Pwr_Spec = [10 1.5e3];
Swath_Spec = [10e3 50e3];

Goal_L2H = [0 1];
Goal_H2L = [1 0];

Goal_Total = func_Individual_Goal(Ant_Dia_Spec, Goal_H2L, Design_Choice.Ant_Dia.El);
Goal_Total = Goal_Total + func_Individual_Goal(Ant_Dia_Spec, Goal_H2L, Design_Choice.Ant_Dia.Az);
Goal_Total = Goal_Total + func_Individual_Goal(Spin_Num_Spec, Goal_L2H, Design_Choice.Num_Scans_on_Target);
Goal_Total = Goal_Total + func_Individual_Goal(Spin_Rate_Spec, Goal_H2L, Design_Choice.Spin_Rate);
Goal_Total = Goal_Total + func_Individual_Goal(Warn_Time_Spec, Goal_L2H, Derived.Twarn);
Goal_Total = Goal_Total + func_Individual_Goal(Dopp_Pre_Spec, Goal_H2L, Derived.Dopp_Meas_Percision);
Goal_Total = Goal_Total + func_Individual_Goal(Xmtr_Pwr_Spec, Goal_H2L, Design_Choice.Xmtr_Pwr);
Goal_Total = Goal_Total + func_Individual_Goal(Swath_Spec, Goal_L2H, Derived.Swath_Width);

Goal_Total = Goal_Total/8;

    function Goal_Indv = func_Individual_Goal(Spec, Goal, Value)
        Goal_Indv = interp1(Spec, Goal, Value, "linear", "extrap");

        if(Goal_Indv > 1)
            Goal_Indv = 1;
        elseif(Goal_Indv < 0)
            Goal_Indv = 0;
        end

    end

end