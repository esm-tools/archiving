#!/bin/bash                                                                                                            
# HINT:                                                                                                                
# * You can change the values right of the "=" as you wish.                                                            
# * The "%j" in the log file names means that the job id will be inserted                                              
#SBATCH --job-name=slk_arch_job # Specify job name                                                                     
#SBATCH --output=slk_job.o%j # name for standard output log file                                                       
#SBATCH --error=slk_job.e%j # name for standard error output log                                                       
#SBATCH --partition=shared # partition name                                                                            
#SBATCH --ntasks=1 # max. number of tasks to be invoked                                                                
#SBATCH --time=08:00:00 # Set a limit on the total run time                                                            
#SBATCH --account=ba0989 # Charge resources on this project                                                            
#SBATCH --mem=6GB                                                                                                      
                                                                                                                       
# make 'module' available when script is submitted from certain environments                                           
source /sw/etc/profile.levante                                                                                         
                                                                                                                       
# ~~~~~~~~~~~~ preparation ~~~~~~~~~~~~                                                                                
module load slk                                                                                                        
                                                                                                                       
EXP=$1                                                                                                                 
YR=$2                                                                                                                  
YR_final=$3                                                                                                            
TS=$4                                                                                                                  
                                                                                                                       
# set the source folder                                                                                                
src_folder=/work/ba0989/a270124/PalModII/experiments/${EXP}/outdata/pism                                               
# set target folder for archival                                                                                       
target_folder=/arch/ab0246/a270124/PalModII/inception/${EXP}/                                                          
                                                                                                                       
COUNT_MAX=60                                                                                                           
                                                                                                                       
#while [[ ! -f ${src_folder}/latest_ex_file_pism.nc ]]                                                                 
#do                                                                                                                    
#    sleep 10                                                                                                          
#    COUNT=$((COUNT+1))                                                                                                
#    if [[ ${COUNT} == ${COUNT_MAX} ]]; then                                                                                                                                                                                                  
#        echo " File ${src_folder}/latest_ex_file_pism.nc not found even after 10 minutes."                            
#        echo " Either PISM couple out takes too long or something went wrong."                                        
#        echo " No archiving of PISM output files! Exit..."                                                            
#        exit -1                                                                                                       
#    fi                                                                                                                
#done                                                                                                                  
                                                                                                                       
# ~~~~~~~~~~~~ archivals ~~~~~~~~~~~~                                                                                  
# do the archival                                                                                                      
echo "doing 'slk archive'"                                                                                             
# ~~~~~~~~~~~~ doing single-file archivals ~~~~~~~~~~~~                                                                
# You can do multiple archivals in one script. The exit code of each                                                   
# archival should be captured afterwards (get $? in line after slk command)                                            
echo " * start year=${YR}; final year=${YR_final}; time step=${TS}"                                                    
while [ ${YR} -lt ${YR_final} ]                                                                                        
do                                                                                                                     
    slk archive -vv ${src_folder}/${EXP}_pismr_extra_${YR}0101-*.nc ${target_folder}                                   
    if [ $? -ne 0 ]; then                                                                                              
        >&2 echo "an error occurred in slk archive call 1"                                                             
    else                                                                                                               
        echo "archival successful"                                                                                     
        rm ${src_folder}/${EXP}_pismr_extra_${YR}0101-*.nc                                                             
    fi                                                                                                                 
    YR=$(( ${YR}+${TS} ))                                                                                              
done                                                                                                                   
