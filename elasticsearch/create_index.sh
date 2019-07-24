#!/bin/bash

curl -XPUT 'localhost:9200/tflat?pretty' -d'
{
    "settings" : {
        "index": {
            "number_of_shards" : 1,
            "number_of_replicas": 0,
            "mapper": {
                "dynamic": false
            },
            "analysis": {
                "analyzer": {
                    "csdefault": {
                        "type": "czech"
                    }
                }
            }
        }
    },
    "mappings" : {
        "nahravka" : {
            "properties" : {
                "prepis" : { "type" : "text", "analyzer": "czech" }
            }
        }
    }
}'

curl -XPUT 'localhost:9200/tarr?pretty' -d'{
    "settings": {
        "index": {
            "number_of_shards" : 1,
            "number_of_replicas": 0,
            "mapper": {
                "dynamic": false
            }
        }
    },
    "mappings": {
        "nahravka": {
            "properties": {
                "slovo": {
                    "properties": {
                        "occurrence": {"type":"keyword"},
                        "timestamp": {"type":"float"},
                        "phonet": {"type":"text"},
                        "humanic": {"type":"boolean"}
                    }
                }
            }
        }
    }
}'

curl -XPUT 'localhost:9200/tking?pretty' -d'{
    "settings": {
        "index": {
            "number_of_shards" : 1,
            "number_of_replicas": 0,
            "mapper": {
                "dynamic": false
            }
        }
    },
    "mappings": {
        "veta": {
            "properties": {
                "occurrences": {
                    "type" : "text", "analyzer": "czech"
                },
                "phonet": {
                    "type": "text", "analyzer": "whitespace"
                },
                "humanicity": { "type": "keyword" }
            }
        }
    }
}'
