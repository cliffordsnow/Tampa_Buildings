#!/bin/bash

CITY=tampa
WORKINGDIR=/home/clifford/OSM/Florida/${CITY}/
OGR2OSM=/home/clifford/bin/ogr2osm.py
PGUSER=postgres
PGDATABASE=mygis
BUILDINGS=fl_${CITY}_bldg
VOTDST=fl_${CITY}_votdst
STORAGE="https://cliffordsnow.github.io/Florida/osm/"

cd ${WORKINGDIR}

#build geojson for the tasking manager
pgsql2shp -f ${VOTDST}  mygis "select '${STORAGE}'|| geoid10 || '.osm.gz' as import_url, geom from fl_${CITY}_votdst;"
ogr2ogr -f GeoJSON ${CITY}.json ${VOTDST}.shp

#for some reason the script above creates an upper case, dam postgres, so we have to convert it to lowercase
sed -e "s/IMPORT_URL/import_url/" ${CITY}.json > ${CITY}.geojson
rm ${CITY}.json

#create a list of votdst ids to use to create the individual .osm files for the tasking manager
psql mygis -c "select geoid10 from fl_${CITY}_votdst" | sed -e 's/^ //' | grep "^[0-9][0-9]" > votdst.lst


#Build the directories if they don't exist
if [ ! -d ${WORKINGDIR}/osm/ ]
then
	mkdir ${WORKINGDIR}/osm/ 
fi
	
if [ ! -d ${WORKINGDIR}/tmp/ ]
then
	mkdir ${WORKINGDIR}/tmp/ 
fi
	
#
# this is the script that creates the individual task .osm files
# Sometimes it takes more than one iteration to get the script right. this just removes the files so it can run again
# 
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

# postgres query to create shapefiles containing the buildings. the sql checks for centroids of buildings inside of the votdst polygon
    pgsql2shp -f ${WORKINGDIR}/tmp/${id}b -h localhost -u ${PGUSER} ${PGDATABASE} "SELECT b.* FROM ${BUILDINGS} b, ${VOTDST} p WHERE ST_CONTAINS(p.geom, st_centroid(b.geom)) AND vtdst10 = '${id}'"
 
 #ogr2osm.py is paul norman's script that converts a shapefile to a .osm file
 #the -t option is for a translation file, in this case ms_bldgs.py. The translation file converts from the postgres column and value
 #to osm k,v tags.
   ${OGR2OSM} -f -t ${WORKINGDIR}/ms_bldg.py ${WORKINGDIR}/tmp/${id}b.shp -o ${WORKINGDIR}/osm/${id}.osm
    
    gzip ${WORKINGDIR}/osm/${id}.osm
done < votdst.lst
