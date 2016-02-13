function [tex_file] = averageTracesSave(cellset, props)

% averageTracesSave - Average all protocols in cellset across cells and save as voltage_clamp MAT files.
%
% Usage:
% [tex_file] = averageTracesSave(cellset, props)
%
% Parameters:
%   cellset: A cellset object.
%   props: Structure with optional parameters.
%     protNames: Cell array of protocol(s) to average.
%     recalc: If 1, recalculate even if saved file is found.
%
% Returns:
%   tex_file: Name of TeX file generated.
%
% Description:
%   Also generates statistics and saves a lot of files. Will create a
% LaTeX document in the proper directory.
%
% See also: cellset_L1, traceset_L1_passive/averageTracesSave, data_L1_passive
%
% $Id: averageTracesSave.m 896 2007-12-17 18:48:55Z cengiz $
%
% Author: Cengiz Gunay <cgunay@emory.edu>, 2011/02/07

% Copyright (c) 2011 Cengiz Gunay <cengique@users.sf.net>.
% This work is licensed under the Academic Free License ("AFL")
% v. 3.0. To view a copy of this license, please look at the COPYING
% file distributed with this software or visit
% http://opensource.org/licenses/afl-3.0.php.

props = mergeStructs(defaultValue('props', struct), get(cellset, 'props'));
doc_dir = getFieldDefault(props, 'docDir', '');

cellset_id = get(cellset, 'id');

% for each protocol set for averaging:
prot_names = ...
    getFieldDefault(props, 'protNames', cellset.treatments.averageTracesSave);

Cm_db_name = [ doc_dir filesep properTeXFilename(cellset_id) ' - Cm DB.mat' ];
prot_tex_file = ...
      [ properTeXFilename([cellset_id '-averages-all-protocols' ]) '.tex' ];

% TODO: if Cm doesn't exist, run that first
if ~exist(Cm_db_name, 'file') || isfield(props, 'recalc')
  [a_db, a_stats_db, Cm_avg_db] = processCapEst(cellset, props);
else
  load(Cm_db_name);
end

prot_tex_str = '';
for prot_name = prot_names
  prot_name = prot_name{1};

  plot_name = ['compare-cap-average-' properTeXFilename(prot_name)];
  tex_file = ...
      [ properTeXFilename([cellset_id '-' plot_name]) '.tex' ];

  prot_zoom = ...
      getFieldDefault(getFieldDefault(props, 'protZoom', struct), ...
                      prot_name, repmat(NaN, 1, 4));

  % names
  avg_file = [ props.docDir filesep properTeXFilename(cellset_id) ' - Average-' properTeXFilename(prot_name) ...
               '.mat' ];
  sd_file = [ props.docDir filesep properTeXFilename(cellset_id) ' - AverageSD-' properTeXFilename(prot_name) ...
              '.mat' ];

  % Do only if files don't exist
  if ~exist(avg_file, 'file') || ~exist(sd_file, 'file') || isfield(props, 'recalc')
    celllist = get(cellset, 'list');
    
    num_cells = length(celllist);
    norm_traces = repmat(trace, 1, num_cells);
    cell_tex_str = '';
    
    % go across cells
    for cell_index = 1:num_cells
      
      traceset = getItemTraceset(cellset, cell_index);
      traceset_id = get(traceset, 'id');
      
      % call averageTracesSave
      % pass zoom param as axisLimits
      [avg_vc sd_vc ts_tex_file] = ...
          averageTracesSave(traceset, prot_name, ...
                            mergeStructs(props, ...
                                         struct('axisLimits', ...
                                                prot_zoom)));      
      sub_vc = avg_vc;
      
      % capacitance normalize
      Cm_val = ...
          get(Cm_avg_db(Cm_avg_db(:, 'Cell_Id') == cell_index, ...
                        {'Cm_avg_pF'}), 'data');
      
      norm_traces(cell_index) = sub_vc.i ./ Cm_val;
      
       cell_tex_str = ...
           [ cell_tex_str '\input{' ts_tex_file '}' sprintf('\n') ];
%                     getTeXString(pas_doc) ];
    end % cell_index
    
    % average across cells
    [avg_tr sd_tr] = avgTraces(norm_traces, struct('id', [cellset_id '-' prot_name]));
    
    avg_vc = set(avg_vc, 'i', avg_tr);
    avg_vc = set(avg_vc, 'id', [cellset_id ' - NormAverage - ' prot_name ]);
    sd_vc = set(avg_vc, 'i', sd_tr);
    sd_vc = set(sd_vc, 'id', [cellset_id ' - NormSD - ' prot_name ]);
    
    % make plot
    plot_title = ...
        [ 'Capacitance normalized and averaged ' properTeXLabel(prot_name) ' protocols from cells of ' ...
          properTeXLabel(cellset_id) '.' ];
    a_doc = doc_plot(plot_superpose({...
      superposePlots(plot_abstract(norm_traces, [ ' - ' plot_title], ...
                                   mergeStructs(props, ...
                                                struct('noTitle', 1, 'ColorOrder', [0.7 0.7 0.7], ...
                                                      'axisLimits', prot_zoom)))), ...
      plot_abstract(avg_tr, '', struct('ColorOrder', [0 0 0], ...
                                       'plotProps', struct('LineWidth', 2)))}, {}, '', ...
                                    struct('noCombine', 1)), ...
                     plot_title, ...
                     [ plot_name ], struct('width', '.7\columnwidth'), ...
                     properTeXLabel([ plot_name '-' cellset_id ]), ...
                     mergeStructs(props, struct('fixedSize', [6 4])));
    
    % this can be done during averaging or after
    % put protocols in tex file, too
    string2File([ '\clearpage\protsection{Averaging ' properTeXLabel(prot_name) '}' sprintf('\n') ...
                  cell_tex_str ...
                  '\clearpage\cellsection{Capacitance-normalized ' properTeXLabel(prot_name) ...
                  ' averages of ' properTeXLabel(cellset_id) ...
                  '}' sprintf('\n') ...
                  getTeXString(a_doc) ], ...
                [ props.docDir filesep tex_file ]);
    
    avg_vc = setProp(avg_vc, 'doc', a_doc);
    
    % save data
    save(avg_file, 'avg_vc');
    save(sd_file, 'sd_vc');
  else
    load(avg_file);
    load(sd_file);
  end % if file exists
  prot_tex_str = [prot_tex_str '\input{' tex_file '}' sprintf('\n') ];
end % prot_name

string2File([ prot_tex_str ], ...
            [ props.docDir filesep prot_tex_file ]);

tex_file = prot_tex_file;