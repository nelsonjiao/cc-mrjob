#!/bin/bash

JOB="$1"
INPUT="$2"
OUTPUT="$3"

if [ -z "$JOB" ] || [ -z "$INPUT" ] || [ -z "$OUTPUT" ]; then
    echo "Usage: $0 <job> <input> <outputdir>"
    echo "  Run a CommonCrawl mrjob on Hadoop"
    echo
    echo "Arguments:"
    echo "  <job>     CCJob implementation"
    echo "  <input>   input path"
    echo "  <output>  input path (must not exist)"
    echo
    echo "Example:"
    echo "  $0  word_count  hdfs://.../wet.paths  hdfs:///.../output/"
    echo
    echo "Note: don't forget to adapt the number of maps/reduces and the memory requirements"
    exit 1
fi

# strip .py from job name
JOB=${JOB%.py}

# wrap Python files for deployment, cf. below option --setup,
# see for details
# http://pythonhosted.org/mrjob/guides/setup-cookbook.html#putting-your-source-tree-in-pythonpath
tar cvfz ${JOB}_ccmr.tar.gz *.py

# number of maps resp. reduces 
NUM_MAPS=250
NUM_REDUCES=10

python $JOB.py \
       -r hadoop \
       --jobconf "mapreduce.map.memory.mb=1200" \
       --jobconf "mapreduce.map.java.opts=-Xmx1024m" \
       --jobconf "mapreduce.reduce.memory.mb=1200" \
       --jobconf "mapreduce.reduce.java.opts=-Xmx1024m" \
       --jobconf "mapreduce.output.fileoutputformat.compress=true" \
       --jobconf "mapreduce.output.fileoutputformat.compress.codec=org.apache.hadoop.io.compress.BZip2Codec" \
       --jobconf "mapreduce.job.reduces=$NUM_REDUCES" \
       --jobconf "mapreduce.job.maps=$NUM_MAPS" \
       --setup 'export PYTHONPATH=$PYTHONPATH:'${JOB}'_ccmr.tar.gz#/' \
       --no-output \
       --cleanup NONE \
       --output-dir "$OUTPUT" \
       "$INPUT"
