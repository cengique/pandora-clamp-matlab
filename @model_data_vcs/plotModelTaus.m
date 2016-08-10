function a_p = plotModelTaus(a_md, title_str, props)

% plotModelTaus - Plot I/V curves comparing model and data.
%
% Usage:
% a_p = plotModelTaus(a_md, title_str, props)
%
% Parameters:
%   a_md: A model_data_vcs object.
%   title_str: (Optional) Text to appear in the plot title.
%   props: A structure with any optional properties.
%     quiet: If 1, only use given title_str.
%		
% Returns:
%   a_p: A plot_abstract object.
%
% Description:
%
% Example:
% >> a_md = model_data_vcs(model, data_vc)
% >> plotFigure(plotModelTaus(a_md, 'I/V curves'))
%
% See also: model_data_vcs, voltage_clamp, plot_abstract, plotFigure
%
% $Id$
%
% Author: Cengiz Gunay <cgunay@emory.edu>, 2010/10/11

if ~ exist('props', 'var')
  props = struct;
end

if ~ exist('title_str', 'var')
  title_str = '';
end

if isfield(props, 'quiet')
  all_title = title_str;
else
  all_title = [ a_md.id get(a_md.model_f, 'id') ' time constants ' title_str ];
end

% find the current (I) object
if isfield(a_md.model_f.f, 'Vm')
  I = a_md.model_f.Vm.I;
elseif isfield(a_md.model_f.f, 'Vm_Vw')
  I = a_md.model_f.Vm_Vw.I;
elseif isfield(a_md.model_f.f, 'I')
  I = a_md.model_f.I;
else
  I = a_md.model_f;
end

if isfield(I.m.props, 'tau_func')
  tau_m = I.m.props.tau_func(I.m);
else
  tau_m = I.m.tau;
end

try get(I, 'h') %ismember(getColNames(I), 'h')
    if isfield(I.h.props, 'tau_func')
      tau_h = I.h.props.tau_func(I.h);
    elseif isfield(struct(I.f.h), 'f')
      tau_h = I.h.tau;
    else
      tau_h = [];
    end
catch exception
    tau_h = [];
end

a_p = { plot_abstract(tau_m, all_title) };

if ~isempty(tau_h)
  a_p = [ a_p, { plot_abstract(tau_h) }];
end

if isfield(I.f, 'h2')
  a_p = [ a_p, { plot_abstract(I.h2.tau) }];
end

a_p = ...
    plot_superpose(a_p);

a_p.props = ...
    mergeStructs(props, ...
                 struct('noTitle', 1, 'fixedSize', [2.5 2], ...
                        'grid', 1, 'plotProps', struct('LineWidth', 2)));
