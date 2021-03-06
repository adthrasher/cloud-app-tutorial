#!/bin/bash
# dx-adapter-trim 0.0.1
# Generated by dx-app-wizard.
#
# Basic execution pattern: Your app will run on a single machine from
# beginning to end.
#
# Your job's input variables (if any) will be loaded as environment
# variables before this script runs.  Any array inputs will be loaded
# as bash arrays.
#
# Any code outside of main() (or any entry point you may add) is
# ALWAYS executed, followed by running the entry point itself.
#
# See https://documentation.dnanexus.com/developer for tutorials on how
# to modify this file.

set -e -x

main() {

    echo "Value of read_one: '$read_one'"
    echo "Value of read_two: '$read_two'"

    # The following line(s) use the dx command-line tool to download your file
    # inputs to the local file system using variable names for the filenames. To
    # recover the original filenames, you can use the output of "dx describe
    # "$variable" --name".

    dx download "$read_one"

    dx download "$read_two"

    # Install conda
    pypath=$PYTHONPATH
    orig_path=$PATH
    export PYTHONPATH=
    wget "https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh" -O miniconda.sh 
    chmod a+x miniconda.sh 
       ./miniconda.sh -b -p /opt/conda/ 
       rm miniconda.sh

    PATH=/opt/conda/bin:$PATH

    conda update -n base -c defaults conda -y && \
       conda install \
       -c conda-forge \
       -c bioconda \
       cutadapt==2.9 \
       -y && \
       conda clean --all -y

    # Fill in your application code here.
    #
    # To report any recognized errors in the correct format in
    # $HOME/job_error.json and exit this script, you can use the
    # dx-jobutil-report-error utility as follows:
    #
    #   dx-jobutil-report-error "My error message"
    #
    # Note however that this entire bash script is executed with -e
    # when running in the cloud, so any line which returns a nonzero
    # exit code will prematurely exit the script; if no error was
    # reported in the job_error.json file, then the failure reason
    # will be AppInternalError with a generic error message.
    forward=
    while read line
    do 
      forward="${forward} -a ${line}" 
    done < /stjude/forward_adapters.txt
    reverse=
    while read line
    do
      reverse="${reverse} -A ${line}"
    done < /stjude/reverse_adapters.txt
    cutadapt ${forward} ${reverse} -o out.1.fastq -p out.2.fastq $read_one_name $read_two_name  

    # The following line(s) use the dx command-line tool to upload your file
    # outputs after you have created them on the local file system.  It assumes
    # that you have used the output field name for the filename for each output,
    # but you can change that behavior to suit your needs.  Run "dx upload -h"
    # to see more options to set metadata.
    export PYTHONPATH=$pypath
    export PATH=$orig_path

    trimmed_read_one=$(dx upload out.1.fastq --brief)
    trimmed_read_two=$(dx upload out.2.fastq --brief)

    # The following line(s) use the utility dx-jobutil-add-output to format and
    # add output variables to your job's output as appropriate for the output
    # class.  Run "dx-jobutil-add-output -h" for more information on what it
    # does.

    dx-jobutil-add-output trimmed_read_one "$trimmed_read_one" --class=file
    dx-jobutil-add-output trimmed_read_two "$trimmed_read_two" --class=file
}
