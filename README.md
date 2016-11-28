# Vlasiator on KNL

##Vlasiator

Vlasiator LINK is a code that simulates plasma, in particular targeting
space weather simulations. It simulates the dynamics of plasma using a
hybrid-Vlasov model, where protons are described by their distribution
function f(r,v,t) in ordinary (r) and velocity (v) space, and
electrons are a charge-neutralising fluid. This approach neglects
electron kinetic effects but retains ion kinetics. The time-evolution
of f(r,v,t) is given by Vlasov's equation, which is coupled
self-consistently to Maxwell's equations giving the evolution of the
electric and magnetic fields E and B.  Vlasiator propagates the
distribution function forward in time with a conservative fifth-order
accurate Semi-Lagrangian algorithm . This algorithm allows using long
time steps even in the presence of strong magnetic fields, as the
propagation in velocity space is not limited by the
Courant-Friedrichs-Levy (CFL) condition. The field solver is a
second-order accurate divergence-free upwind-constrained transport
method.

Vlasiator uses a Cartesian mesh (http://github.com/fmihpc/dccrg) in
ordinary space. Each cell contains the field variables (B, E), as well
as a 3D sparse velocity mesh. Empty velocity space cells are neither
stored nor propagated, which in a typical case reduces the total
number of phase space cells by a factor of at least 100. In large
scale simulations there are typically on the order of a few million
spatial-cells in ordinary space, with in total 10<sup>12</sup> cells
in the full distribution function.

The cartesian mesh is parallelized with MPI, and uses the Zoltan
library for dynamic load balancing. It relies heavily on user defined
MPI datatypes. The code is futhermore threaded. Typically loops over
spatial cells have been threaded, but where the fata dependencies
demand also other approaches have been used. Finally the Vlasov
solver, representing up to 90% of total run-time, is vectorized using
an explicit approach based on using the Agner Fogg's vectorclass LINK.
 
## Intel Xeon Phi - Knights Landing



## Porting 

The github branch where the neccessary changes were done is visible
here LINK.  The main changes were:

  * Added the interface to utilize also the Vec16f and Vec8d datatypes in vectorclass.
  * Added the correct compiler flags to enable good performance on the KNL
 
The main challenges was that the code was not compatitable with the
Intel MPI stack. Using the MPI library, version 16 or 17, lead to
crashes very early on. On other MPI libraries the code is, however,
very stable. The root cause for this was not identified. By compiling
OpenMPI and utilizing that good performance could be achieved on a KNL
development platform.



## Performance
# Test cases 

To test the performance of the code three test cases have been
created, which have different size. Each of them are a very low
resolution version of a real space weather simulation, that fits on
one node.

| Test   | Spatial cells | Phase space cells | Total Memory (GB) |
| Small  | 2500          |                   | 1                 |
| Medium | 2500          |                   | 9                 |
| large  | 10000         |                   | 40                |



### Vectorization 
  

### Optimal run parameters

To investigate optimal balance of threads and MPI processes we run the
code with 4 threads per core, 256 threads in total, varying the number
of processes. 

|        |   1   |   4  | 8   | 16   | 32   | 64   |
| Small  |  48.7 | 64.0 |71.6 | 83.5 | 89.6 | 87.1 |
| Medium | 154.5 | 112.5| 110.4 | 110.2 | 108.8 | 107.1|
| Large  | 74.9  | 110.7 | 108.8 |112.9 |111.3 | 113.9|  
Table. Performance if GigaCellss/s as a function of number of processes





 MPI - openmp balance
 HT on / off 
 affinities 


### Memory usage
 Cache vs ddt vs on mcdram
 jemalloc vs. no
 huge pages



## Conclusions and outlook

Threading can be improved
investigate decreasing need for dynamic memory allocation (acc?).
	    	       