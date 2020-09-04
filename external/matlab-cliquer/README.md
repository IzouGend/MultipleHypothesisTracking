Description
--------------------
This project contains a MATLAB package containing a MEX interface to the C program [Cliquer](http://users.tkk.fi/pat/cliquer.html/), which contains a collection of optimized routines for finding cliques in graphs.  A (very slightly) modified version of the Cliquer project is included here for convenience (and because a slight modification was required to make the MEX compiler happy on my machine).

Additional README and LICENSE files for Cliquer can be found in the directory `+Cliquer/cliquer/`.  This project currently utilizes only a small subset of Cliquer's functionality (specifically a portion dealing with unweighted graphs).

Usage
--------------------
0. Ensure that your MEX compiler is functioning.  You can test this by entering the directory `+Cliquer/mex_test/` in MATLAB and executing the command `mex hello_world.c`.  If that command produces an error, then your MEX compiler is not functioning properly.  Otherwise, the command should produce a MEX function `hello_world.mex<suffix>`, where `<suffix>` depends on your OS; now, executing the MATLAB command `hello_world` should produce the output `Hello, World!`.

1. Ensure that the `+Cliquer` directory is a subdirectory of a directory in your MATLAB path.  Do *not* add the `+Cliquer` directory to your MATLAB path.

2. Execute the MATLAB command `Cliquer.Compile()` to compile both the C program Cliquer and the MEX interface.  This compile function is provided for convenience but basically just compiles Cliquer, compiles the MEX function, and then moves the MEX function into the package directory.

3. Cliquer's functionality can now be accessed with the command `Cliquer.FindAll`, and documentation can be accessed with `help Cliquer.FindAll`.