function b = subsref(a,index)
% subsref - Defines generic indexing for objects.
%
% Author: Cengiz Gunay <cgunay@emory.edu>, 2004/08/04

% Copyright (c) 2007 Cengiz Gunay <cengique@users.sf.net>.
% This work is licensed under the Academic Free License ("AFL")
% v. 3.0. To view a copy of this license, please look at the COPYING
% file distributed with this software or visit
% http://opensource.org/licenses/afl-3.0.php.
if size(index, 2) > 1
  first = subsref(a, index(1));
  % recursive
  b = subsref(first, index(2:end));
else
  switch index.type
    case '()'
      b = a(index.subs{:});
    case '.'
      b = get(a, index.subs);
    case '{}'
      b = a{index.subs{:}};
  end
end