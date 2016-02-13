function a_p = plotSteadyIV(a_vc, step_num, title_str, props)

% plotSteadyIV - Plot of the I/V curve at the end of a voltage step.
%
% Usage:
% a_p = plotSteadyIV(a_vc, step_num, title_str, props)
%
% Parameters:
%   a_vc: A voltage clamp object.
%   step_num: 1 for prestep, 2 for the first step, 3 for next, etc.
%   title_str: (Optional) Text to appear in the plot title.
%   props: A structure with any optional properties.
%     quiet: If 1, only use given title_str.
%     curUnit: Display units for current trace (default='nA').
%     label: add this as a line label to be used in superposed plots.
%     plotPeaks: If 1, use the props.iPeaks instead of steady-state.
%     stepRange: Uses the relative [start end] times in [ms] around 
%       time of step_num to calculate the current averages. If vector has
%       3 items, first one is the step number, which can be different
%       than step_num.
%		
% Returns:
%   a_p: A plot_abstract object.
%
% Description:
%   Can be superposed with other I/V plot objects (see plot_superpose).
%
% Example:
% >> a_vc = abf_voltage_clamp('data-dir/cell-A.abf')
% >> plotFigure(plotSteadyIV(a_vc, 2, 'I/V curve'))
%
% See also: voltage_clamp, plot_abstract, plotFigure, plot_superpose
%
% $Id$
%
% Author: Cengiz Gunay <cgunay@emory.edu>, 2010/03/10

% TODO: 

if ~ exist('props', 'var')
  props = struct;
end

% TODO: make this part a private function; it is shared between this and
% plot_abstract
cur_unit = getFieldDefault(props, 'curUnit', 'nA');

switch (cur_unit)
  case 'nA'
    cur_scale = 1;
  case 'pA'
    cur_scale = 1e3;
  otherwise
    error([ 'props.curUnit = ''' cur_unit ...
            ''' not recognized. Use only nA or pA.']);
end

if ~ exist('title_str', 'var')
  title_str = '';
end

plot_label = getFieldDefault(props, 'label', 'data');

dt = get(a_vc, 'dt') * 1e3;             % convert to ms

data_i = get(a_vc.i, 'data');
data_v = get(a_vc.v, 'data');
cell_name = get(a_vc, 'id');
time = (0:(size(data_i, 1)-1))*dt;
vc_props = get(a_vc, 'props');

if isfield(props, 'quiet')
  all_title = properTeXLabel(title_str);
else
  all_title = ...
      properTeXLabel([ 'I/V curve: ' cell_name title_str ]);
end

if isfield(props, 'plotPeaks')
  i_steps = vc_props.iPeaks;
elseif isfield(props, 'stepRange')
  if length(props.stepRange) > 2
    cur_step_num = props.stepRange(1);
    props.stepRange = props.stepRange(2:3);
  else
    cur_step_num = step_num;
  end
  props.stepRange = a_vc.time_steps(cur_step_num) + ...
      round(props.stepRange / dt);
  i_steps = ...
      mean(a_vc.i.data(props.stepRange(1):props.stepRange(2), :));
else
  i_steps = a_vc.i_steps(step_num, :);
end

a_p = ...
    plot_abstract(...
      {a_vc.v_steps(step_num, :), i_steps * cur_scale}, ...
      {[ 'step ' num2str(step_num) ' voltage [mV]' ], [ 'current [' cur_unit ']' ]}, ...
      all_title, {plot_label}, 'plot', ...
      mergeStructsRecursive(props, ...
                            struct('tightLimits', 1, ...
                                   'plotProps', struct('LineWidth', 2))));
