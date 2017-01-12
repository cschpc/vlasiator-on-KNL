#####################################################################################################
# Run parameters - please edit
#####################################################################################################

mpilibrary="openmpi"                          #openmpi or intel
range_hyperthreads="1 2 4"                    # Numbr of threads per core
range_processes="1 2 4 8 16 32 64"            # Number of processes (threads computed to fill cores)
range_i_mpi_pin_order="compact"               # I_MPI_PIN_ORDER values
range_kmp_affinity="compact scatter none" # KMP_AFFINITY values
range_forcemcdram="0"                       # Force allocations to mcdram in flat mode. "0","1" or "0 1". 
                                              # If 1 it adds numactl commands (supports Quadrant, SNC-2, SNC-4)


#run parameters only applicable to singleparametersweep.sh. These are
#fixed, and one at a time loops through ranges

default_hyperthreads=4
default_processes=16
default_i_mpi_pin_order="compact"
default_kmp_affinity="compact" 
default_forcemcdram=0

