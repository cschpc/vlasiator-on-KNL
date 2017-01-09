
# VLASIATOR 

[Vlasiator](http://vlasiator.fmi.fi) is a code that simulates plasma,
in particular targeting space weather simulations. It simulates the
dynamics of plasma using a hybrid-Vlasov model, where protons are
described by their distribution function f(r,v,t) in ordinary (r) and
velocity (v) space, and electrons are a charge-neutralising
fluid. This approach neglects electron kinetic effects but retains ion
kinetics. The time-evolution of f(r,v,t) is given by Vlasov's
equation, which is coupled self-consistently to Maxwell's equations
giving the evolution of the electric and magnetic fields E and
B. Vlasiator propagates the distribution function forward in time with
a conservative fifth-order accurate Semi-Lagrangian algorithm . This
algorithm allows using long time steps even in the presence of strong
magnetic fields, as the propagation in velocity space is not limited
by the Courant-Friedrichs-Levy (CFL) condition. The field solver is a
second-order accurate divergence-free upwind-constrained transport
method.

Vlasiator uses a Cartesian mesh library in ordinary space,
parallelized with the [DCCRG](http://github.com/fmihpc/dccrg)
library. Each cell contains the field variables (B, E), as well as a
3D sparse velocity mesh. This velocity mesh is based on blocks of 4 x
4 x 4 cells, and is sparse in the sense that empty velocity space
blocks are neither stored nor propagated, which in a typical case
reduces the total number of phase space cells by a factor of at least
100. In large scale simulations there are typically on the order of a
few million spatial-cells in ordinary space, with in total
10<sup>12</sup> cells in the full distribution function.

The cartesian mesh is parallelized with MPI, and uses the Zoltan
library for dynamic load balancing. It relies heavily on user defined
MPI datatypes. The code is futhermore threaded. Typically loops over
spatial cells have been threaded, but when propagatig f(r,v) in
ordinary space the threading is over velocity blocks.
where the data dependencies demand also other
approaches have been used. Finally the Vlasov solver, representing up
to 90% of total run-time, is vectorized using an explicit approach
based on using the Agner Fogg's
[vectorclass](http://www.agner.org/optimize/#vectorclass).
 

## Porting 

### Platform

The code has been ported to be run on a test platform with the Intel
Knights Landing (KNL) processor, specifically an Xeon Phi Processor
7210, sporting 64 cores running at a base frequency of 1.3 GHz with
DDR4-2133 memory.  The operating system is CentOS 7.2 and Intel
Parallel Studio version 17.0.1 was used.

### Code modifications

The github branch where the neccessary changes were done is visible
[here](https://github.com/galfthan/vlasiator/tree/core-level-ipcc).
The main changes were:

  * Added an interface to utilize the Vec16f and Vec8d datatypes in vectorclass.
  * Added the correct compiler flags to enable good performance on the KNL
 
The main challenges was that the code was not compatitable with the
Intel MPI stack. Using the MPI library, version 16 or 17, lead to
crashes very early on. Using other MPI libraries the code is, however,
very stable. The root cause for this was not identified. By compiling
OpenMPI and utilizing that, good performance could be achieved on the
KNL platform described below.


## Performance

### Test cases 

To test the performance of the code three [test cases](/tests) have
been created. Each of them represent a low resolution version of a
real space weather simulation, that fits on one node. The "small" case
uses 1 GB of memory, the "medium" case uses 8 GB of memory and the
"large" case 40 GB of memory.


### Compiler options and vectorization 

To begin with we tested various compiler flags, but did not see any
significant improvement beyond

```
-O2  -xMIC-AVX512 -std=c++11 -qopenmp -ansi-alias
```

Vlasiator uses Agners vectorclass for vectorizing the computationally
most intensive parts of the code, namely the vlasov propagation. The
C++ template library provides vector datatypes, e.g., Vec16F, which
represents 16 single precision floating point numbers. Operations on
these are then compiled to vector intrinsics.  To enable the
vectorclass to support 512 bit long vectors one needs to further
define `` -DMAX_VECTOR_SIZE=512``.

Additionally Vlasiator also supports a fallback code path, which
relies on the compiler to do all vectorization.

In the following table three variants of the codes was compiled, using
the fallback code path, VEC8F vectors which map to AVX2 intrinsice and
VEC16F vectors which map to AVX512 intrinsics. The measurements are in
millions of cell updates per second, and higher is better. These were
run with 16 MPI processes, each spawning 16 threads.


|            | Fallback   | VEC8F  | VEC16F
|------------|------------|--------|-------------
|    small   |        30  |     65 |       80
|    medium  |        37  |     87 |      107
|    large   |        38  |     88 |      109


It can be seen that the vectorclass fares significantly better than
the fallback code path, and that the code sees a good speedup from
using AVX512 intrinsics.

### Memory allocators

Vlasiator does a lot of dynamic memory allocation and deallocation,
and performance is affected byt the chosen allocator. Here we compare
the default allocator, jemalloc 4.2.1 and tbbmalloc. These tests were
run with 16 MPI processes, each spawning 16 threads, and supporting
AVX512 using Agner's vectorclass.

|            | malloc     | jemalloc|  tbbmalloc
|------------|------------|---------|-------------
|    small   |      80    |      82 |          85
|    medium  |     107    |     107 |         140
|    large   |     109    |     117 |         147


It can be seen that for small systems all allocators have similar
performance, but for larger datasets tbbmalloc is clearly superior on
KNL.


### Optimal run parameters


To investigate optimal balance of threads and MPI processes we run the
code with 4 threads per core, 256 threads in total, varying the number
of processes. These tests were run with the optimal choices from
above, so with AVX512 support using Agner's vectorclass and tbbmalloc.


|            | 1 x 256  | 2 x 128 |  4 x 64  |  8 x 32 | 16 x 16 | 32 x 8 | 64 x 4
|------------|----------|---------|----------|---------|---------|--------|-----
|    small   |      52  |      61 |      68  |     74  |     85  |    88  |    89
|    medium  |     167  |     143 |     144  |    142  |    140  |   133  |   126
|    large   |     153  |     148 |     151  |    148  |    147  |   143  |   141


The performance is fairly even, with 1 process and 256 threads being
optimal for large cases and 1 process per core being optimal for the
small case. For multinode simulations we expect the 1 process per node
option to be less than ideal, one reason for its good performance is
the lack of MPI overhead for this one node case. In general 16
processes with 16 threads each seems like a good and balanced choice.

Furthermore we investigated the effect of hyperthreads, and 4 threads
per core was clearly the optimal choice. For medium and large test
cases 4 threads per core was almost twice as fast as 1.


|            | 1          |  2      |   4
|------------|------------|---------|-------------
|    small   | 59         |  81     |  85
|    medium  | 75         | 113     | 140
|    large   |78          |  119    | 147


### MCDRAM utilization

Furthermore we also tested the performance of running the code purely
from DDR, and running the small and medium case purely from MCDRAM. As
expected cache mode was better than using only DDR, while using only
MCDRAM was fastest. On the other hand the scientifically relevant
simulations would be using more memory than available on the MCDRAM so
the cache mode is the correct choice for Vlastiator.

### Performance comparison

In the table below we have compared the performance of Vlasiator on
the Xeon Phi test platform, to its performance on one node on
Sisu.csc.fi. On this machine each node has two 2.6 GHz Haswell
processor, each with 12 cores.

|            |  Xeon Phi |  Xeon 
|------------|------------|---------
|    small   |     85     | 181
|    medium  |     140    | 217
|    large   |     147    | 216


The table shows that for larger simulations, which are most relevant
for actual science runs, the Xeon node is 47% faster.  

## Conclusions

We have shown that the code is able to use AVX512 vector instructions,
and to be able to employ the MPI + OpenMP paralellization well on the
processor. Fruthermore, the dynamic memory utilization benefitted from
tbbmalloc.

The performance is still not competitive with a normal Xeon node, but
there is still hope for improving the situation. By re-structuring the
Vlasov solver one could decrease the need for time-consuming lookups
from unordered maps, and furthermore there are multiple places where
one could either add or improve threading performance.

