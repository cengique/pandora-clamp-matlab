function params = ...
      scale_IClCa_NaP_sub_IClCa(a_vc, props)

% scale_IClCa_NaP_sub_IClCa - Scale IClCa and steady-state of INaP from voltage-step protocol data and subtract IClCa.
%
% Usage:
% params = scale_IClCa_NaP_sub_IClCa(a_vc, props)
%
% Parameters:
%   a_vc: A voltage clamp object.
%   props: A structure with any optional properties.
%     saveData: If 1, save subtracted data into a new text file (default=0).
%     plotPrepulse: If 1, show plot of prepulse current change with
%       voltage (default=0).
%		
% Returns:
%   params: Structure with tuned parameters.
%
% Description:
%   Made for Na recordings from the oocyte. While estimating IClCa, one
% needs to consider INaP since it counteracts IClCa.
%
% Example:
% >> a_vc = abf_voltage_clamp('data-dir/cell-A.abf')
% >> params = scale_IClCa_NaP_sub_IClCa(a_vc)
%
% See also: voltage_clamp, param_I_v, param_func
%
% $Id$
%
% Author: Cengiz Gunay <cgunay@emory.edu>, 2010/02/05

% TODO: 
% - process 2nd step and write a 2nd data file for prepulse step
% - get lower/upper limits from param_func
% - prepare a doc_multi from this. Find a way to label figures but print later.
% - also plot IClCa m_infty curve?
% - have option to show no plots, to create database of params

global f_IClCa_minf_v f_IClCa_tau_v m_ClCa f_IClCa_v f_INaP_minf_v

if ~ exist('props', 'var')
  props = struct;
end

dt = get(a_vc, 'dt') * 1e3;             % convert to ms

data_i = get(a_vc.i, 'data');
data_v = get(a_vc.v, 'data');
cell_name = get(a_vc, 'id');
time = (0:(size(data_i, 1)-1))*dt;

% find step start
t_step_start = find_change(data_v(:, 1), 1, 3);
  
% find step ends
t_step_end = find_change(data_v(:, 1), t_step_start + 20 / dt, 3);

% calc prepulse steady-state values
range_prepulse = (t_step_start - 10 / dt) : (t_step_start - 8 / dt);
v_prepulse = ...
    mean(data_v( range_prepulse, : ));
i_prepulse = ...
    mean(data_i( range_prepulse, : )); % Do for each current separately

% calc step steady-state values
range_steps = (t_step_end - 5 / dt) : (t_step_end - 1 / dt);
v_steps = ...
    mean(data_v( range_steps, : ), 1);

i_steps = ...
    mean(data_i( range_steps, : ), 1);

if isfield(props, 'plotPrepulse')
  % plot prepulse drift
  plotFigure(...
    plot_abstract(...
      {v_steps, i_prepulse}, ...
      {'step voltage [mV]', 'prepulse current [nA]'}, ...
      [ cell_name ': noise from prepulse' ], ...
      {'data'}, 'plot', ...
      struct('fixedSize', [2.5 2], ...
             'tightLimits', 1, 'plotProps', struct('LineWidth', 2))));
  end
  
  % nicely plot current and voltage trace in separate axes  
  plotFigure(...
    plot_stack({...
      plot_abstract({time, data_i}, {'time [ms]', 'I [nA]'}, ...
                    'all currents', {}, 'plot', struct), ...
      plot_abstract({time, data_v}, {'time [ms]', 'V_m [mV]'}, ...
                    'all currents', {}, 'plot', struct)}, ...
               [t_step_start * dt - 10, t_step_end * dt + 10 NaN NaN], ...
               'y', [ cell_name ': Raw data' ], ...
               struct('titlesPos', 'none', 'xLabelsPos', 'bottom', ...
                      'fixedSize', [4 3], 'noTitle', 1)));

  % model NaP like  
  % INaP = gNaP * m ^ p * (V - ENa);
  % minf = @(V)1/(1+exp((V-Vhalf)/(k)));
  ENa = 45;
  
  % at this point this is still tainted by IClCa
  % so optimize to get both I_NaP and I_ClCa params
  
  %minf_ClCa = @(V)1./(1+exp((V-1.59)./(-19.47)));
  mtau_ClCa = 58; % ms
  EClCa = -41.7; % mV
  
  % correct for IClCa not having reached its steady state
  %Vpre = 28.3; % mV
  Vpre = v_prepulse(1);
  m0_ClCa = f(f_IClCa_minf_v, Vpre);
  v_delay = 2; % ms, for space clamp error delay
  end_act = ...
    (1 - exp(- (t_step_end - t_step_start - v_delay) * dt ./ f(f_IClCa_tau_v, Vpre)));

  % func of sum of NaP and ClCa

  % let tune both NaP parameters as they may be different 
  % in the splice variants
  f_INaP_minf_v = setProp(f_INaP_minf_v, 'selectParams', {'V_half', 'k'}); % 
                                                              %'k'
                                                              
  % and IClCa parameters, because some splice variants seem to have
  % different values for these (?)
  f_IClCa_minf_v = setProp(f_IClCa_minf_v, 'selectParams', {'V_half', 'k'}); % 
                                                              
  %f_INaP_minf_v = setParam(f_INaP_minf_v, 'V_half', -60);
  %m_inf_ClCa = f_IClCa_minf_v;
  f_steady = param_mult(...
    {'voltage [mV]', 'current [nA]'}, ...
    [4.7 ENa 1 EClCa], ...
    {'gmax_NaP', 'ENa', 'gmax_ClCa', 'EClCa'}, ...
    struct('minf_NaP', f_INaP_minf_v, 'minf_ClCa', f_IClCa_minf_v), ...
    @(fs, p, x) deal(((p.gmax_NaP .* f(fs.minf_NaP, x)) ...
                 .* (x - p.ENa) + ...
                 p.gmax_ClCa * ...
                 (m0_ClCa + (f(fs.minf_ClCa, x) - m0_ClCa) * end_act) ...
                 .* (x - p.EClCa)), NaN), ...
    'I_{NaP} + I_{ClCa}', ...
    struct('xMin', -90, 'xMax', 30));
  
  % limit tunable paramters to these
  f_steady = setProp(f_steady, 'selectParams', ... % 
                               {'gmax_ClCa', 'ENa', 'gmax_NaP', 'EClCa'}); 

  %  MSE of (observed - fit)
  error_func = ...
      @(p)mse([i_steps] - ...
              f(setParams(f_steady, p, struct('onlySelect', 1)), ...
                [v_steps ]));
  
  error_func_lsq = ...
      @(p, x)f(setParams(f_steady, p, struct('onlySelect', 1)), x);
  
  par = getParams(f_steady, struct('onlySelect', 1)); % initial params
                                                      
  %[par, fval, exitflag, output] = ...
  %    fminsearch(error_func, par', optimset('MaxIter', 1000))
  [par, resnorm, residual, exitflag, output] = ...
      lsqcurvefit(error_func_lsq, par', v_steps, i_steps, ...
                  [1e-4 0   1e-4 -90 -80 -50   -80 -50], ...
                  [40   60  40   -30 -0  -1e-2 -0  -1e-2], ...
                  optimset('MaxIter', 1000, 'Display', 'notify', ...
                           'MaxFunEvals', 1000))

  % set back fitted parameters
  f_steady = setParams(f_steady, par, struct('onlySelect', 1));
  
  % then, extract all parameters
  params = getParamsStruct(f_steady)

  % overwrite some variables
  f_INaP_minf_v = f_steady.f.minf_NaP;
  f_IClCa_minf_v = f_steady.f.minf_ClCa;
  ENa = params.ENa;
  EClCa = params.EClCa;
  
  % plot estimated I_ClCa & I_NaP separately and together
  i_ClCa = ...
      params.gmax_ClCa .* (m0_ClCa + (f(f_IClCa_minf_v, v_steps) - m0_ClCa) * end_act) .* (v_steps - EClCa); % nA
  i_steps_est = f(f_steady, v_steps);
  i_NaP_est = i_steps_est - i_ClCa;
  
  % plot subtracted I_NaP/V plot
  plotFigure(plot_superpose({...
    plot_abstract(...
      {v_steps, i_steps - i_ClCa, '+'}, ...
      {'voltage [mV]', 'est. I_{NaP} [nA]'}, ...
      [ cell_name ': est. I_{NaP} as I/V' ], ...
      {'data - I_{ClCa}'}, 'plot', ...
      struct('tightLimits', 1)), ...
    plot_abstract(...
      {v_steps, i_NaP_est}, ...
      {'voltage [mV]', 'current [nA]'}, ...
      '', {'est. I_{NaP}'}, 'plot', ...
      struct('tightLimits', 1, 'fixedSize', [2.5 2], 'noTitle', 1, ...
             'plotProps', struct('LineWidth', 2), 'noLegends', 1))}));
  
  % plot m_inf_NaP superposed on data
  m_NaP_steps = (i_steps - i_ClCa) ./ ...
      (params.gmax_NaP * (v_steps - ENa));
  
  minf_nap = @(V)1./(1+exp((V-params.V_half_NaP)./params.k_NaP));
  V=-100:1:100;
  plotFigure(plot_superpose({...
    plot_abstract(...
      {v_steps, m_NaP_steps, '+'}, ...
      {'voltage [mV]', 'NaP activation, m_\infty'}, ...
      [ cell_name ': m_\infty for NaP' ], ...
      {'data - I_{ClCa}'}, 'plot', ...
      struct), ...
    plot_abstract(...
      {V, f(f_INaP_minf_v, V)}, ...
      {'voltage [mV]', 'activation, m_{NaP}'}, ...
      '', {'NaP m_\infty'}, 'plot', ...
      struct('axisLimits', [-90 20 NaN NaN], 'noLegends', 1, ...
             'fixedSize', [2.5 2], 'noTitle', 1, ...
             'plotProps', struct('LineWidth', 2)))}));
  
  % plot all fits over data
  plotFigure(plot_superpose({...
    plot_abstract(...
      {v_steps, i_steps, '+'}, ...
      {'voltage [mV]', 'current [nA]'}, ...
      [ cell_name ': estimates superposed on data I/V' ], ...
      {'data'}, 'plot', ...
      struct('tightLimits', 1)), ...
    plot_abstract(...
      {v_steps, i_steps_est}, ...
      {'voltage [mV]', 'current [nA]'}, ...
      '', {'fit'}, 'plot', ...
      struct), ...
    plot_abstract(...
      {v_steps, i_steps_est - i_ClCa}, ...
      {'voltage [mV]', 'current [nA]'}, ...
      '', {'est. I_{NaP}'}, 'plot', ...
      struct('tightLimits', 1)), ...
    plot_abstract(...
      {v_steps, i_ClCa}, ...
      {'voltage [mV]', 'current [nA]'}, ...
      '', {'est. I_{ClCa}'}, 'plot', ...
      struct('tightLimits', 1, 'fixedSize', [2.5 2], 'noTitle', 1, ...
             'plotProps', struct('LineWidth', 2))) }));

% subtract IClCa and save
f_IClCa_v = setParam(f_IClCa_v, 'gmax', params.gmax_ClCa);
f_IClCa_v = setParam(f_IClCa_v, 'E', EClCa);
f_IClCa_v.f.m = setFunc(f_IClCa_v.f.m, 'inf', f_IClCa_minf_v);

% choose the range
range_steps = (t_step_start - 10 / dt) : (t_step_end - 0 / dt);

% integrate IClCa for each voltage step

for step_v = 1:length(v_steps)
  IClCa(1:length(range_steps), step_v) = ...
      f(f_IClCa_v, { data_v(range_steps - v_delay/dt, step_v ), dt});
end

% subtract the 2nd step part
data_sub_ClCa = data_i;
data_sub_ClCa(range_steps, :) = data_sub_ClCa(range_steps, :) - IClCa;

% TODO: do we need to subtract NaT also? Maybe just one or two traces
% compromised, ignore for now. Otherwise we need to subtract IClCa from
% the whole trace and then fit DmNav10 NaT

v_legend = ...
    cellfun(@(x)([ sprintf('%.0f', x) ' mV']), num2cell(v_steps'), ...
                            'UniformOutput', false);

% superpose over data
line_colors = lines(length(v_steps)); %hsv(length(v_steps));
plotFigure(...
    plot_stack({...
      plot_superpose({...
        plot_abstract({time, data_i}, {'time [ms]', 'I [nA]'}, ...
                    'data', v_legend, 'plot', ...
                      struct('ColorOrder', line_colors)), ...
        plot_abstract({time(range_steps), IClCa}, ...
                      {'time [ms]', 'I [nA]'}, ...
                    'est. I_{ClCa}', {}, 'plot', ...
                      struct('plotProps', struct('LineWidth', 1), ...
                             'ColorOrder', line_colors))}, ...
                     {}, '', struct('axisProps', ...
                             struct())), ...
      plot_abstract({time, data_sub_ClCa}, ...
                    {'time [ms]', 'I - I_{ClCa}'}, ...
                    'data - I_{ClCa}', {}, 'plot', ...
                    struct('ColorOrder', line_colors, ...
                           'plotProps', struct('LineWidth', 1)))}, ...
               [t_step_start * dt - 10, t_step_end * dt + 10 NaN NaN], ...
               'y', [ cell_name ': Raw data' ], ...
               struct('titlesPos', 'none', 'xLabelsPos', 'bottom', ...
                      'fixedSize', [4 3], 'noTitle', 1)));

if isfield(props, 'saveData')
  %%
  % write to text file for NeuroFit
  dlmwrite([ cell_name ' sub IClCa.txt' ], [time, data_sub_ClCa], ' ' );
end

function t_change = find_change(data, idx_start, num_mV)
% find starting baseline
  first_ms = 2;
  t_begin = first_ms/dt;
  v_start = mean(data(idx_start:(idx_start + t_begin)));
  %v_start_sd = std(data(idx_start:(idx_start + t_begin)));
  
  % find beginning of step
  t_change = find(abs(data(idx_start:end) - v_start) > num_mV); %5*v_start_sd
  t_change = idx_start - 1 + t_change(1);
end

end
