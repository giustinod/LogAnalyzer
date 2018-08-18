# accept eventlog in input
LOG_FILE=$1
CRL_FILE=$2

if [ ! -n "$2" ]; then
   CRL_FILE=./cross_reference_list
fi

declare -A cross_ref_list
#       -A option declares associative array.

while read -r e i; do 
	if [[ $e == I_* ]]; 
	then
		str=${i//[[:cntrl:]]/}
		cross_ref_list[$str]=$e
	fi;
done < $CRL_FILE

# echo "${!cross_ref_list[*]}"   # The array indices ...


if [ ! -n "$1" ]; then
   LOG_FILE=./eventlog
fi

FILE_CSV=temp.csv

rm $FILE_CSV

# run MT commands to convert in CSV
export EVLTMPLPATH=./templates
./mt/www/bin/mtevlview --reverse --templates --formatstr "%data%" --log $LOG_FILE | ./mt/www/bin/formatter --search_string 'alarm' | tr '\n' ' ' | tr '\015' '\n' | sed 's/^ //' >> $FILE_CSV

# &
# wait %1

# index remove
# curl -XDELETE 'localhost:9200/mtlog_v1?pretty'

# index template definition
curl -XPUT 'localhost:9200/_template/mtlog_template?pretty' -H 'Content-Type: application/json' -d'
{
  "template": "mtlog_*",
  "settings": {
    "number_of_shards": 1
  },
  "mappings": {
   "logrec": {
      "properties": {
        "Date": {
          "type": "date",
          "format": "YYYY-MM-dd"
        },
        "Time": {
          "type": "date",
          "format": "HH:mm:ss"
        },
        "identity": {
          "type": "integer"
        },
        "nbr_reactivations": {
          "type": "integer"
        },
        "nbr_seconds_active": {
          "type": "integer"
        },
        "second": {
          "type": "integer"
        },
        "microsecond": {
          "type": "integer"
        },
        "nbr_parameters": {
          "type": "integer"
        },
        "os_date": {
          "type": "date",
          "format": "YYYY:MM:dd"
        },
        "os_time": {
          "type": "date",
          "format": "HH:mm:ss"
        },
        "ip_address": {
          "type": "ip"
        },
        "nbr_trap_parameters": {
          "type": "integer"
        }
      }
    }
  }
}'

# pipeline definition
curl -XPUT 'http://localhost:9200/_ingest/pipeline/parse_logrec_csv?pretty' -H 'Content-Type: application/json' -d'
{
 "processors": [
   {
     "grok": {
       "field": "logrec",
       "patterns": [ 
          "%{DATA:Date},%{DATA:Time},%{DATA:Type},%{DATA:Information},%{DATA:Group},%{NUMBER:Code},%{DATA:Status},%{DATA:Class},%{DATA:Cause},%{DATA:Consequence},%{DATA:Action},identity=%{NUMBER:identity},nbr_reactivations=%{NUMBER:nbr_reactivations},nbr_seconds_active=%{NUMBER:nbr_seconds_active},second=%{NUMBER:second},microsecond=%{NUMBER:microsecond},nbr_parameters=%{NUMBER:nbr_parameters},os_date=%{DATA:os_date},os_time=%{DATA:os_time},sys_up_time=%{DATA:sys_up_time},ip_address=%{DATA:ip_address},mac_address=%{DATA:mac_address},location=%{DATA:location},trap_oid=%{DATA:trap_oid},nbr_trap_parameters=%{NUMBER:nbr_trap_parameters},trap_parameters=%{DATA:trap_parameters}",
          "%{DATA:Date},%{DATA:Time},%{DATA:Type},%{DATA:Information},%{DATA:Group},%{NUMBER:Code},%{DATA:Status},%{DATA:Class},%{DATA:Cause},%{DATA:Consequence},%{DATA:Action},identity=%{NUMBER:identity},nbr_reactivations=%{NUMBER:nbr_reactivations},nbr_seconds_active=%{NUMBER:nbr_seconds_active},second=%{NUMBER:second},microsecond=%{NUMBER:microsecond},nbr_parameters=%{NUMBER:nbr_parameters},cabinet=%{DATA:cabinet},ycu=%{DATA:ycu}",
          "%{DATA:Date},%{DATA:Time},%{DATA:Type},%{DATA:Information},%{DATA:Group},%{NUMBER:Code},%{DATA:Status},%{DATA:Class},%{DATA:Cause},%{DATA:Consequence},%{DATA:Action},identity=%{NUMBER:identity},nbr_reactivations=%{NUMBER:nbr_reactivations},nbr_seconds_active=%{NUMBER:nbr_seconds_active},second=%{NUMBER:second},microsecond=%{NUMBER:microsecond},nbr_parameters=%{NUMBER:nbr_parameters}"
       ]
     }
   },
   {
     "remove": {
       "field": "logrec"
     }
   }
 ]
}'

prefix="IPU object "

# read the CSV file and ingest into Elasticsearch
while read f1
do
   # replace semicolon with comma 
   str=${f1//;/,}
   # remove double quote
   str2=${str//\"/}
   # pipe with comma
   str21=${str2// | /,}
   # remove control characters
   str3=${str21//[[:cntrl:]]/}
   # echo "$str3"

   str4=$str3
   if [[ $str3 =~ $prefix([0-9]+) ]];
   then
	echo ${BASH_REMATCH[1]} 
	# read associative array and replace
	str4=${str3//$prefix${BASH_REMATCH[1]}/$prefix${cross_ref_list[${BASH_REMATCH[1]}]}}
        echo "$str4"
   fi

   curl -XPOST 'http://localhost:9200/mtlog_v1/logrec?pipeline=parse_logrec_csv&pretty' -H 'Content-Type: application/json' -d" { \"logrec\" : \"$str4\" }"
   # echo " { \"logrec\" : \"$str4\" } "
done < $FILE_CSV
