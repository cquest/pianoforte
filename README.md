# Piano-Forte

A world map in two flavours:

- Piano, when you need a very light background to put data on top of if
- Forte, when you need a generic purpose map

And three languages: French, English, Arabic.

##  Forte

![screenshot from 2017-10-02 09-33-18](https://user-images.githubusercontent.com/146023/31072322-af868880-a767-11e7-8981-3d0bd8403cc8.png)
![screen shot 2017-10-31 at 18 50 50-fullpage](https://user-images.githubusercontent.com/146023/32240046-837f0386-be6c-11e7-813d-82bde3b35384.png)

## Piano

![screenshot from 2016-08-23 08-50-12](https://cloud.githubusercontent.com/assets/146023/17882745/bde02780-690e-11e6-9c8e-d422a8753956.png)
![screenshot from 2016-08-23 08-51-19](https://cloud.githubusercontent.com/assets/146023/17882746/bde0200a-690e-11e6-9e71-82482f118a54.png)


## Local installation

Create a `pianoforte` PSQL database:

    sudo -u postgres createdb pianoforte -O youruser

Clone this repository:

    git clone https://github.com/tilery/pianoforte

Compile the world boundaries:

    make boundary

Download the PBF from Geofabrik:

    make download

Note: you can use another area by setting the `PBF` env var to the Geofabrik
relative path (default is: africa/egypt-latest.osm.pbf).

Import the PBF and the boundaries into the database:

    make import

Copy the localconfig sample, and change the db configuration inside:

    cp localconfig.js.sample localconfig.js

Run kosmtik with forte:

    kosmtik serve forte.yml

Or with piano:

    kosmtik serve piano.yml


## Production deployment

### Overview

- tiles are generated by the classic [mod_tile](https://github.com/openstreetmap/mod_tile)/[Mapnik](https://mapnik.org/) stack
- Mapnik XML files are distributed in [dist/ folder](https://github.com/tilery/pianoforte/tree/master/dist) in this repository
- OSM data is managed by [Imposm](https://github.com/omniscale/imposm3)
- custom data (including boundaries, country labels, main city labels) is managed by [mae-boundaries](https://github.com/tilery/mae-boundaries)

### Dependencies

- postgresql
- postgis
- gdal
- apache2
- [imposm](https://github.com/omniscale/imposm3)
- [mod-tile](https://github.com/openstreetmap/mod_tile) (see
  [osmadmins/ppa](https://launchpad.net/%7Eosmadmins/+archive/ubuntu/ppa) for Ubuntu)


### Instructions

- create a database with postgis extension:

        createdb tilery
        psql tilery -c "CREATE EXTENSION IF NOT EXISTS postgis"

Note: the database is named `tilery` to follow conventions in the Mapnik XML
generated in the [dist/](https://github.com/tilery/pianoforte/tree/master/dist)
of the project, see below.

- grab Mapnik XML, fonts, icons, Imposm mapping…:

        git clone https://github.com/tilery/pianoforte /path/to/pianoforte --depth 1

- download OSM data

        wget https://planet.openstreetmap.org/pbf/planet-latest.osm.pbf

- download coastline data

        cd data
        wget -N https://osmdata.openstreetmap.de/download/simplified-land-polygons-complete-3857.zip
        unzip -jo simplified-land-polygons-complete-3857.zip
        wget -N https://osmdata.openstreetmap.de/download/land-polygons-split-3857.zip
        unzip -jo land-polygons-split-3857.zip
        cd -

- import OSM data

        imposm import -diff -config /path/to/imposm.conf -read /path/to/planet-latest.osm.pbf -overwritecache -write -deployproduction

- download and import boundary data

        wget http://nuage.yohanboniface.me/boundary.json
        ogr2ogr --config PG_USE_COPY YES -lco GEOMETRY_NAME=geometry -lco DROP_TABLE=IF_EXISTS -f PGDump boundary.sql /path/to/boundary.json -sql 'SELECT name,"name:en","name:fr","name:ar","name:es","name:de","name:ru",iso FROM boundary' -nln itl_boundary
        psql -d tilery --file /path/to/boundary.sql

- download and import city names

        wget https://raw.githubusercontent.com/tilery/mae-boundaries/master/city.csv
        ogr2ogr --config PG_USE_COPY YES -lco GEOMETRY_NAME=geometry -lco DROP_TABLE=IF_EXISTS -f PGDump city.sql /path/to/city.csv -select name,'name:en','name:fr','name:ar',capital,type,prio,ldir -nln city -oo X_POSSIBLE_NAMES=Lon* -oo Y_POSSIBLE_NAMES=Lat* -oo KEEP_GEOM_COLUMNS=NO -a_srs EPSG:4326
        psql -d tilery --file /path/to/city.sql

- download disputed areas

        wget http://nuage.yohanboniface.me/disputed.json -O data/disputed.json

- create custom DB indexes

        psql -d tilery -c "CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_road_label ON osm_roads USING GIST(geometry) WHERE name!='' OR ref!=''" &
        psql -d tilery -c "CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_boundary_low ON osm_admin USING GIST(geometry) WHERE admin_level IN (3, 4)" &

- in renderd configuration file (/etc/renderd.conf) add one section for any
  flavour/language you want to support:

        [fortefr]
        URI=/fortefr/
        TILEDIR=/srv/tilery/tmp/tiles
        XML=/srv/tilery/pianoforte/fortefr.xml
        HOST=localhost
        TILESIZE=256
        MAXZOOM=20
        CORS=*

- if you want retina support, add dedicated sections, example:

        [fortefr2x]
        URI=/fortefr@2x/
        TILEDIR=/srv/tilery/tmp/tiles
        XML=/srv/tilery/pianoforte/fortefr.xml
        HOST=localhost
        TILESIZE=512
        SCALE=2
        MAXZOOM=20
        CORS=*

- configure `mod_tile`; create `/etc/apache2/mods-available/tile.load` with this content:

        LoadModule tile_module /usr/lib/apache2/modules/mod_tile.so

- create `/etc/apache2/mods-available/tile.load` with this content:

        <IfModule tile_module>
            LoadTileConfigFile /etc/renderd.conf
            ModTileRenderdSocketName /var/run/renderd/renderd.sock
            # Timeout before giving up for a tile to be rendered
            ModTileRequestTimeout 0
            # Timeout before giving up for a tile to be rendered that is otherwise missing
            ModTileMissingRequestTimeout 30
        </IfModule>

- run renderd

        /usr/bin/renderd -f -c /etc/renderd.conf
