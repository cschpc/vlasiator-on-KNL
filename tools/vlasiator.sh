
#####################################################################################################
# Define code - please edit
#####################################################################################################

bindir=$(pwd) 
#bins="vlasiator_rv_1 vlasiator_rv_2 vlasiator_rv_3  vlasiator_rv_4 vlasiator_rv_5"
bins="vlasiator_rv_6"

 # Binary name (with absolute path)
parameters="--run_config=magnetosphere.cfg"  #run parameters
testfolder=$(pwd)"/tests" #folder where tests are stored (absolute path)
#tests="small medium large" #name of test folders within testfolder (multiple allowes)
tests="small medium large"

#function for computing performance (perf) and execution time (time). Executed in run folder
function get_perf()
{
    perf=0
    for f in phiprof_*.txt
    do
	procs=$(grep "Set of identical timers has" $f |gawk '{printf $8}')
	temp=$(grep "Propagate   " $f  |gawk -v perf=$perf -v procs=$procs '{printf perf + procs * $21}')
	perf=$temp
    done
    time=$(grep "Propagate   " phiprof_0.txt  |gawk '{printf $11}')
	
}

#application specific env variables
export PHIPROF_PRINTS="full"

export TBB_MALLOC_USE_HUGE_PAGES=1

#For debug, setting 
export TBB_VERSION=1 


