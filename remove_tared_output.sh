#!/bin/bash
#this script uses previously prepared file lists (see script tar_spinup.sh) and deletes any files listed in them
#this script performs the clean up stage after you have executed tar_spinup.sh (and verified that tarballs have been generated in that process without errors, check the log files of individual tar jobs)
#this script assumes that the simulation folder is located in a subfolder of name EXPID that is present in the directory where this script resists and is called
#the scripts expects the file lists for file deletion to be present in subfolder archive
#this script does not touch any other files than those listed in the file list files, in particular no tar balls of tarred model output. Such have to be deleted manually after verifying that a (manually performed) transfer to the tape archive has finished without errors.

#get command line arguments
expid="$1" #EXPID of the simulation

#general settings, adjust where necessary
outpath=${expid}/archive

#proceed only if EXPID is provided
if [ "$#" -eq 0 ]
then
  echo "Error: you must provide the name of the simulation as command line argument #1"
else
  #first step: get a list of text files that are available
  echo "getting file lists for simulation ${expid} ..."
  file_lists=$(ls ${outpath}/file_list_*.txt)
  echo "files listed in the following file lists will be removed:"
  echo ${file_lists} | sed "s# #\n#g"
  read -p "press Y and ENTER to proceed, any other key and ENTER to quit without deleting any files: " decision
  if [ "$decision" == "Y" ]
  then
    for file_list in ${file_lists}
    do
      echo "deleting files listed in ${file_list}"
      while read file
      do
        #echo "deleting file $file ..."
        rm "$file"
      done < ${file_list}
    done
  else
    echo "quitting without deleting any files ..."
  fi
fi
