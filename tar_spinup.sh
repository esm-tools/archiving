#!/bin/bash
#this script tars output of esm-tools-based simulations from the outdata folder to a new archive folder, defined via variable outpath below, that will be located in parallel to restart, scripts, outdata, etc. folders
#this script assumes that the simulation folder is located in a subfolder of name EXPID that is present in the directory where this script resists and is called
#in a first step, this script creates text files that split the files of a given simulation into chunks for submodels and years
#these text files are stored in outpath
#in a second step, this script reads above generated text files and tars all files mentioned in there into tarballs
#for speed compressing is done via SLURM jobs using parallel gzip 

#get command line arguments
expid="$1" #EXPID of the simulation
task="$2" #compress_only assumes that chunks have already be organized and only the compressing should be done

#general settings, adjust where necessary
outpath=${expid}/archive/
chunk_size=100
echam_infile_pattern="EXPID_YYYYMM.01_accw EXPID_YYYYMM.01_co2 EXPID_YYYYMM.01_echam EXPID_YYYYMM.01_ism"
jsbach_infile_pattern="EXPID_YYYYMM.01_jsbach EXPID_YYYYMM.01_land EXPID_YYYYMM.01_surf EXPID_YYYYMM.01_veg EXPID_YYYYMM.01_yasso"
fesom_infile_pattern="a_ice.fesom.YYYY.nc Av.fesom.YYYY.nc bolus_u.fesom.YYYY.nc bolus_v.fesom.YYYY.nc bolus_w.fesom.YYYY.nc fh.fesom.YYYY.nc fw.fesom.YYYY.nc Kv.fesom.YYYY.nc m_ice.fesom.YYYY.nc MLD1.fesom.YYYY.nc MLD2.fesom.YYYY.nc MLD3.fesom.YYYY.nc m_snow.fesom.YYYY.nc N2.fesom.YYYY.nc Redi_K.fesom.YYYY.nc salt.fesom.YYYY.nc ssh.fesom.YYYY.nc sss.fesom.YYYY.nc sst.fesom.YYYY.nc temp.fesom.YYYY.nc tx_sur.fesom.YYYY.nc ty_sur.fesom.YYYY.nc u.fesom.YYYY.nc uice.fesom.YYYY.nc unod.fesom.YYYY.nc v.fesom.YYYY.nc vice.fesom.YYYY.nc vnod.fesom.YYYY.nc w.fesom.YYYY.nc"

#get current working directory (to reconstruct absolute paths within the tarballs)
pwd=$(pwd)

#proceed only if EXPID is provided
if [ "$#" -eq 0 ]
then
  echo "Error: you must provide the name of the simulation as command line argument #1"
else
  #first step: generate the text files that list content for specific tar balls (chunks)
  #each submodel's files will go to separate chunks
  #this step can be bypassed if a second command line argument with value compress_only is provided when calling this script
  #that way, incomplete tar jobs can be repeated without the need to regenerate the file partitioning
  if [ "${task}" != "compress_only" ]
  then
    if [ -e ${outpath} ]
    then
    
      echo "error: refuse writing to existing archiving path ${outpath}, clean up first!"
    
    else
      
      echo "splitting simulation files into different chunks and storing in ${outpath} ..."
      mkdir ${outpath}
      
      #get first and last year (this script will consider all years for taring for which echam data exists at the simulation's outdata/echam directory)
      year1=$(ls ${expid}/outdata/echam/${expid}_??????.01_echam | head -n 1 | sed -e "s#${expid}/outdata/echam/##" | sed -e "s#${expid}##" | sed -e "s#_##" | cut -c 1-4)
      year2=$(ls ${expid}/outdata/echam/${expid}_??????.01_echam | tail -n 1 | sed -e "s#${expid}/outdata/echam/##" | sed -e "s#${expid}##" | sed -e "s#_##" | cut -c 1-4)
    
      #define file name patterns and settings for monthly vs. annual output - these will generally differ between models
      for i in echam jsbach fesom
      do
        echo "working on submodel $i ..."
        if [ $i == "echam" ]
        then
          file_pattern="${echam_infile_pattern}"
          monthly=true
        fi
        if [ $i == "jsbach" ]
        then
          file_pattern="${jsbach_infile_pattern}"
          monthly=true
        fi
        if [ $i == "fesom" ]
        then
          file_pattern="${fesom_infile_pattern}"
          monthly=false
        fi
        
        #construct the absolute path for input files by supplying the present working directory from which this script has been called
        inpath=${pwd}/${expid}/outdata/${i}
        
        #loop over all years and organize files into chunks of ~chunk_size years
        for start in $(seq $year1 ${chunk_size} $year2)
        do
          #create file that will list all files of this chunk
          this_chunk_file_list="${outpath}/file_list_${i}_${start}-$((${start}+${chunk_size}-1)).txt"
          if [ -e ${this_chunk_file_list} ]
          then
            rm ${this_chunk_file_list}
          fi
          touch ${this_chunk_file_list}
          
          #generate file names for this archival chunk and store them in the file list
          echo "preparing ${this_chunk_file_list} ..."
          for ((n = 0 ; n < ${chunk_size} ; n++))
          do
            y="$(($start+$n))"
            echo "generating file names for model year $y"
            if [ $monthly ]
            then
              for m in 01 02 03 04 05 06 07 08 09 10 11 12
              do
                for f in ${file_pattern}
                do
                  fname=$(echo ${f} | sed "s#EXPID#${expid}#" | sed "s#YYYY#${y}#" | sed "s#MM#${m}#" )
                  echo ${inpath}/${fname} >>${this_chunk_file_list}
                done
              done
            else
              fname=$(echo ${f} | sed "s#EXPID#${expid}#" | sed "s#YYYY#${y}#")
              echo ${inpath}/${fname} >>${this_chunk_file_list}
            fi
          done
          echo "------"
        done
      done
    fi
  fi
  
  #based on all file lists generated above, create tarballs for all chunks
  #we do this in parallel using parallel gzip (pigz)
  #to this end this script writes for each archival job a SLURM SBATCH script that is then submitted
  chunk_lists=$(ls ${outpath}/file_list*.txt)
  for file_list in $chunk_lists
  do
    tarball=$(echo $file_list | sed "s#.txt#.tgz#")
    echo "creating tarball $tarball from file list $file_list ..."
    #tar czf $tarball --files-from=$file_list
    #tar c -I"gzip --best" -f $tarball --files-from=$file_list
    echo "writing SLURM job ..."
    file_list_no_path="$(basename $file_list)"
cat <<EOF > $tarball.job
#!/bin/bash
#SBATCH --partition=smp
#SBATCH --account=paleodyn.paleodyn
#SBATCH --qos=12h
#SBATCH --time=6:00:00
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=20
#SBATCH --output=$tarball.%j.out
#SBATCH --error=$tarball.%j.out
cd ${pwd}/${outpath}
tar c -I"pigz --best" -f $(basename $tarball) --files-from=${file_list_no_path}
EOF
     echo "submitting SBATCH script ..."
     sbatch $tarball.job
  done
  wait
  
  #TODO: 1.) check job output and error streams for any problems
  #      2.) if there are none, transfer tarballs to archive servers
  #      3.) all files that are listed in the list files for each and every chunk can be deleted (there should be a separate script to do that, still in work)
fi
