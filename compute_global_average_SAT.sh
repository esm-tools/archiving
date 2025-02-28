#!/bin/bash
  
module load cdo/1.9.10
module load ncview

expid=$1
n_years=$2

if [ $# -eq 0 ]
then
  echo "Error: you must provide the name of the simulation as command line argument #1"
else
  cdo -f nc4c -z zip6 -t echam6 select,name=temp2 ${expid}/outdata/echam/${expid}_??????.01_echam ${expid}_temp2.nc
  cdo -f nc4c -z zip6 runmean,5 -yearmonmean -fldmean ${expid}_temp2.nc ${expid}_SAT.nc
  ncview ${expid}_SAT.nc&
  #rm ${expid}_temp2.nc
  sleep 5
  if [ $# -eq 2 ]
  then
    echo "computing trend over the last ${n_years} years ..."
    last_year=$(cdo showyear ${expid}_SAT.nc | tr "\n" " " | awk '{print $NF}')
    first_year=$(echo "${last_year}-${n_years}+1" | bc)
    #echo $first_year
    #echo $last_year
    cdo -f nc4c -z zip6 -timmean -yearmonmean -selyear,${first_year}/${last_year} ${expid}_temp2.nc ${expid}_temp2_timeavg_${first_year}_${last_year}.nc
    cdo selyear,${first_year}/${last_year} ${expid}_SAT.nc ${expid}_SAT_last_${n_years}.nc
    cdo trend ${expid}_SAT_last_${n_years}.nc trend1.nc trend2.nc
    trend=$(cdo outputf,%13.6g trend2.nc)
    trend_all=$(echo "scale=6; ${trend}/(${last_year}-${first_year}+1)*100" | bc)
    echo "trend over the last ${n_years} years: ${trend_all} °C"
    echo "computing average over the last ${n_years} years ..."
    mean=$(cdo output -subc,273.15 -fldmean -timmean -yearmonmean ${expid}_SAT_last_${n_years}.nc)
    echo "average over the last ${n_years} years: ${mean} °C"
    rm trend1.nc trend2.nc
  fi
  rm ${expid}_temp2.nc
fi
