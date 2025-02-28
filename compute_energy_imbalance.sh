#!/bin/bash
  
module load cdo/1.9.10
module load ncview

expid=$1
n_years=$2

if [ $# -eq 0 ]
then
  echo "Error: you must provide the name of the simulation as command line argument #1"
else
  cdo -f nc4c -z zip6 -t echam6 select,name=trad0 ${expid}/outdata/echam/${expid}_??????.01_echam ${expid}_trad0.nc
  cdo -f nc4c -z zip6 -t echam6 select,name=srad0 ${expid}/outdata/echam/${expid}_??????.01_echam ${expid}_srad0.nc
  cdo -f nc4c -z zip6 runmean,5 -yearmonmean -fldmean -add ${expid}_trad0.nc ${expid}_srad0.nc ${expid}_energy_balance.nc
  ncview ${expid}_energy_balance.nc&
  rm ${expid}_?rad0.nc
  sleep 5
  if [ $# -eq 2 ]
  then
    echo "computing trend over the last ${n_years} years ..."
    last_year=$(cdo showyear ${expid}_energy_balance.nc | tr "\n" " " | awk '{print $NF}')
    first_year=$(echo "${last_year}-${n_years}+1" | bc)
    cdo selyear,${first_year}/${last_year} ${expid}_energy_balance.nc ${expid}_energy_balance_last_${n_years}.nc
    cdo trend ${expid}_energy_balance_last_${n_years}.nc trend1.nc trend2.nc
    trend=$(cdo outputf,%13.6g trend2.nc)
    trend_all=$(echo "scale=6; ${trend}/(${last_year}-${last_year}+1)*100" | bc)
    echo "trend over the last ${n_years} years: ${trend_all} W/m² per century"
    #echo "scale=6; ${trend}/(${last_year}-${first_year}+1)*100"
    rm trend1.nc trend2.nc
  fi
fi
