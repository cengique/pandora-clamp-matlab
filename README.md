pan_clamp - Pandora Matlab toolbox module for voltage and current clamp recordings
=======================================================================

pan_clamp is an object-oriented Matlab toolbox for working with
neuronal voltage and current clamp recordings. With the addition of
the `pan_fit` module, it can fit models to voltage clamp data.

Prerequisites
--------------------

- Pandora Toolbox - Get from [Github](https://github.com/cengique/pandora-matlab) or [Mathworks 
  FileExchange](https://www.mathworks.com/matlabcentral/fileexchange/60237-cengique-pandora-matlab)
- Pandora's `pan_fit` module - Get
  from [Github](https://github.com/cengique/pandora-fit-matlab)
  or [Mathworks File Exchange](https://www.mathworks.com/matlabcentral/fileexchange/124050-pan_fit)

Installation:
--------------------

Use the addpath Matlab command to add the pan_clamp/ subdirectory to the
Matlab search path. For example: 

```matlab
>> addpath my/download/dir/pandora-clamp-matlab-x.y.z/pan_clamp
```

To avoid doing this every time you start Matlab in Windows, use the
'File->Set path' menu option and add the pandora/ directory to the
search path. Or, create a startup.m file in the '$HOME/matlab'
directory in In UNIX/Linux and 'My Documents/MATLAB' directory in
Windows with the above addpath command inside.

Documentation:
--------------------

See the [`examples/`](examples/) folder for:
- [Fitting passive and active properties from voltage clamp data](examples/passive_active_fits.m)
- [Fitting a dataset of multiple files at once (files not provided)](examples/passive_fits_traceset.m)

For usage of functions and classes, see the embedded documentation
that comes with each file using the Matlab help browser.

Copyright:
--------------------

Copyright (c) 2010-23 Cengiz Gunay <cengique@users.sf.net>.
This work is licensed under the Academic Free License ("AFL")
v. 3.0. To view a copy of this license, please look at the COPYING
file distributed with this software or visit
http://opensource.org/licenses/afl-3.0.txt.
