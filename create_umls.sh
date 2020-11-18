#!/bin/sh

echo 'Dropping existing mrconso table'
sqlite3 umls.db "drop table if exists mrconso"

echo 'Creating mrconso table'
sqlite3 umls.db "create table mrconso (
        CUI	char(8) NOT NULL,
        LAT	char(3) NOT NULL,
        TS	char(1) NOT NULL,
        LUI	char(8) NOT NULL,
        STT	varchar(3) NOT NULL,
        SUI	char(8) NOT NULL,
        ISPREF	char(1) NOT NULL,
        AUI	varchar(9) NOT NULL,
        SAUI	varchar(50),
        SCUI	varchar(50),
        SDUI	varchar(50),
        SAB	varchar(20) NOT NULL,
        TTY	varchar(20) NOT NULL,
        CODE	varchar(50) NOT NULL,
        STR	text NOT NULL,
        SRL	int NOT NULL,
        SUPPRESS	char(1) NOT NULL,
        CVF	int
      );"

# Remove the last pipe from each line
if [ ! -e MRCONSO.pipe ]
then
 echo 'Removing last pipe from RRF'
 sed -e 's/|$//' -e "s/\"/'/g" ./resources/terminology/umls_subset/MRCONSO.RRF > MRCONSO.pipe
fi

echo 'Populating mrconso table'
sqlite3 umls.db ".import MRCONSO.pipe mrconso"

echo 'Dropping existing mrrel table'
sqlite3 umls.db "drop table if exists mrrel;"

echo 'Creating mrrel table'
sqlite3 umls.db "create table mrrel (
        CUI1	char(8) NOT NULL,
        AUI1	varchar(9),
        STYPE1	varchar(50) NOT NULL,
        REL	varchar(4) NOT NULL,
        CUI2	char(8) NOT NULL,
        AUI2	varchar(9),
        STYPE2	varchar(50) NOT NULL,
        RELA	varchar(100),
        RUI	varchar(10) NOT NULL,
        SRUI	varchar(50),
        SAB	varchar(20) NOT NULL,
        SL	varchar(20) NOT NULL,
        RG	varchar(10),
        DIR	varchar(1),
        SUPPRESS	char(1) NOT NULL,
        CVF	int
      );"

# Remove the last pipe from each line
if [ ! -e MRREL.pipe ]
then
 echo 'Removing last pipe from RRF'
 sed 's/|$//' ./resources/terminology/umls_subset/MRREL.RRF > MRREL.pipe
fi

echo 'Populating mrrel table'
sqlite3 umls.db ".import MRREL.pipe mrrel"

echo 'Dropping existing mrsat table'
sqlite3 umls.db "drop table if exists mrsat;"

echo 'Creating mrsat table'
sqlite3 umls.db "create table mrsat (
        CUI 	char(8) NOT NULL,
        LUI       char(8),
        SUI       char(8),
        METAUI    varchar(20),
        STYPE	varchar(50) NOT NULL,
        CODE      varchar(50),
        ATUI      varchar(10) NOT NULL,
        SATUI     varchar(10),
        ATN       varchar(50),
        SAB	      varchar(20) NOT NULL,
        ATV       varchar(1000) NOT NULL,
        SUPPRESS	char(1),
        CVF	int
      );"

# Remove the last pipe from each line, and quote all the fields/escape double quotes
# Because MRSAT has stray unescaped quotes in one of the fields
if [ ! -e MRSAT.pipe ]
then
 echo 'Removing last pipe from RRF'
 sed 's/|$//' ./resources/terminology/umls_subset/MRSAT.RRF | sed $'s/"/""/g;s/[^|]*/"&"/g' > MRSAT.pipe
fi

echo 'Populating mrsat table'
sqlite3 umls.db ".import MRSAT.pipe mrsat"

echo 'Indexing mrsat(ATN,ATV)'
sqlite3 umls.db "create index idx_at on mrsat(ATN,ATV);"

echo 'Indexing mrconso(tty)'
sqlite3 umls.db "create index  idx_tty on mrconso(tty);"

echo 'Indexing mrrel(rel,sab)'
sqlite3 umls.db "create index idx_isa on mrrel(REL,SAB);"

echo 'Indexing mrconso(aui)'
sqlite3 umls.db "CREATE INDEX idx_aui ON mrconso(AUI);"

echo 'Analyzing Database'
sqlite3 umls.db "ANALYZE;"
