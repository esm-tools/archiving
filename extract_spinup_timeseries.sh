#!/bin/bash

module load cdo

expid="$1"
fesom_mesh_des="$2"
if [ "$#" -eq 0 ]
then
  echo "Error: you must provide the name of the simulation as command line argument #1"
else

  std_mesh="/albedo/work/projects/paleo_pool/meshes/mesh_core2/core2_griddes_nodes.nc"
  #alternative LP: /albedo/work/projects/p_paleo_compute/stepanek/esm_tools_6_PlioMIP3_production/meshes/LP/midpli1/sl.grid.CDO.nc
  if [ -z "$2" ]
  then
    echo "you did not specify a mesh description file - using CORE2 modern mesh description at"
    echo "${std_mesh}"
    fesom_mesh_des="${std_mesh}"
  fi
    
  #define/get some general parameters
  remapping="remapcon"
  res="r360x180"
  outpath=${expid}/outdata/
  year1=$(ls ${expid}/outdata/echam/${expid}_??????.01_echam | head -n 1 | sed -e "s#${expid}/outdata/echam/##" | sed -e "s#${expid}##" | sed -e "s#_##" | cut -c 1-4)
  year2=$(ls ${expid}/outdata/echam/${expid}_??????.01_echam | tail -n 1 | sed -e "s#${expid}/outdata/echam/##" | sed -e "s#${expid}##" | sed -e "s#_##" | cut -c 1-4)
  #extract from echam output the following quantities and store them in one file covering the whole spinup period
  # 142   1 aprl                                                                0.00    1.00 large scale precipitation [kg/m**2s]
  # 143   1 aprc                                                                0.00    1.00 convective  precipitation [kg/m**2s]
  # 164   1 aclcov                                                              0.00    1.00 total cloud cover []
  # 165   1 u10                                                                 0.00    1.00 10m u-velocity [m/s]
  # 166   1 v10                                                                 0.00    1.00 10m v-velocity [m/s]
  # 167   1 temp2                                                               0.00    1.00 2m temperature [K]
  # 169   1 tsurf                                                               0.00    1.00 surface temperature [K]
  # 171   1 wind10                                                              0.00    1.00 10m windspeed [m/s]
  # 175   1 albedo                                                              0.00    1.00 surface albedo []
  # 178   1 srad0                                                               0.00    1.00 net top solar radiation [W/m**2]
  # 179   1 trad0                                                               0.00    1.00 top thermal radiation (OLR) [W/m**2]
  # 182   1 evap                                                                0.00    1.00 evaporation [kg/m**2s]
  # 184   1 srad0d                                                              0.00    1.00 top incoming solar radiation [W/m**2]
  # 216   1 wimax                                                               0.00    1.00 maximum 10m-wind speed [m/s]
  inpath=${expid}/outdata/echam/
  cdo -f nc4c -z zip6 -t echam6 select,code=142,143,164,165,166,167,169,171,175,178,179,182,184,216 ${inpath}/${expid}_??????.01_echam ${outpath}/${expid}_spinup_${year1}_${year2}_selected_echam_variables.nc
  
  #also extract some fesom output
  #a_ice: sea ice area
  #MLD2: mixed layer depth
  #sss: sea surface salinity
  #sst: sea surface temperature
  inpath=${expid}/outdata/fesom/
  for i in a_ice MLD2 sss sst
  do
    cdo -f nc4c -z zip6 select,name=${i} ${inpath}/${i}.fesom.????.nc ${outpath}/${expid}_spinup_${year1}_${year2}_fesom_${i}.nc
    cdo -f nc4c -z zip6 ${remapping},${res} -setgrid,${fesom_mesh_des} ${outpath}/${expid}_spinup_${year1}_${year2}_fesom_${i}.nc ${outpath}/${expid}_spinup_${year1}_${year2}_fesom_${i}_${remapping}_${res}.nc
  done
fi
