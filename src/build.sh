#!/bin/bash

WORKINGDIR=/home/clifford/OSM/Florida/Tampa/
OGR2OSM=/home/clifford/bin/ogr2osm.py
PGUSER=postgres
PGDATABASE=mygis
BUILDINGS=fl_tampa_bldg
VOTDST=fl_tampa_votdst

cd ${WORKINGDIR}

if [ ! -d ${WORKINGDIR}/osm/ ]
then
	mkdir ${WORKINGDIR}/osm/ 
fi
	
if [ ! -d ${WORKINGDIR}/tmp/ ]
then
	mkdir ${WORKINGDIR}/tmp/ 
fi
	

while read line
do
    id=`echo $line |awk '{print $1}'`

    if [ -e ${WORKINGDIR}/tmp/${id}a.shp ]
    then
      echo "Removing old files"
      rm ${WORKINGDIR}/tmp/${id}b.shp
      rm ${WORKINGDIR}/tmp/${id}b.shx
      rm ${WORKINGDIR}/tmp/${id}b.prj
      rm ${WORKINGDIR}/tmp/${id}b.dbf
      rm ${WORKINGDIR}/tmp/${id}b.osm
    fi

    if [ -e ${WORKINGDIR}/osm/${id}.osm.gz ]
    then
      rm ${WORKINGDIR}/osm/${id}.osm.gz
    fi

    pgsql2shp -f ${WORKINGDIR}/tmp/${id}b -h localhost -u ${PGUSER} ${PGDATABASE} "SELECT b.* FROM ${BUILDINGS} b, ${VOTDST} p WHERE ST_CONTAINS(p.geom, st_centroid(b.geom)) AND vtdst10 = '${id}'"
    ${OGR2OSM} -f -t ${WORKINGDIR}/ms_bldg.py ${WORKINGDIR}/tmp/${id}b.shp -o ${WORKINGDIR}/osm/${id}.osm
    
    gzip ${WORKINGDIR}/osm/${id}.osm
done < votdst.lst
