# add command MT to convert binary log to csv

FILE_CSV=$1

curl -XPUT 'http://localhost:9200/_ingest/pipeline/parse_logrec_csv?pretty' -H 'Content-Type: application/json' -d'
{
 "processors": [
   {
     "grok": {
       "field": "logrec",
       "patterns": [ 
          "%{DATA:Date},%{DATA:Time},%{DATA:Type},%{DATA:Information},%{DATA:Group},%{NUMBER:Code},%{DATA:Status},%{DATA:Class},%{DATA:Cause},%{DATA:Consequence},%{DATA:Action},identity=%{NUMBER:identity},nbr_reactivations=%{NUMBER:nbr_reactivations},nbr_seconds_active=%{NUMBER:nbr_seconds_active},second=%{NUMBER:second},microsecond=%{NUMBER:microsecond},nbr_parameters=%{NUMBER:nbr_parameters},os_date=%{DATA:os_date},os_time=%{DATA:os_time},sys_up_time=%{DATA:sys_up_time},ip_address=%{DATA:ip_address},mac_address=%{DATA:mac_address},location=%{DATA:location},trap_oid=%{DATA:trap_oid},nbr_trap_parameters=%{NUMBER:nbr_trap_parameters},trap_parameters=%{DATA:trap_parameters}",
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

# remove first two lines
# sed -i ‘1,2d' $FILE_CSV

# read the CSV file and ingest into Elasticsearch
while read f1
do
   # replace semicolon with comma, double quote with single quote, remove control characters
   str=${f1//;/,}
   str2=${str//\"/}
   str21=${str2// | /,}
   str3=${str21//[[:cntrl:]]/}
   # echo $str3
   curl -XPOST 'http://localhost:9200/mtlog_v1/logrec?pipeline=parse_logrec_csv&pretty' -H 'Content-Type: application/json' -d" { \"logrec\" : \"$str3\" }"
   # echo " { \"logrec\" : \"$str3\" } "
done < $FILE_CSV

