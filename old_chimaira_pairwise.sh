#!/bin/bash
#SBATCH -o /home/garbe/chimaira/pairwise-%a.txt
#SBATCH --job-name=hercules-sqlite
#SBATCH -p chimaira
#SBATCH -A spl
#SBATCH --get-user-env
#SBATCH --ntasks 1
#SBATCH --array=0-2339

#SBATCH --time=00:05:00 # 5 minutes max

#SBATCH --cpus-per-task 1   # 1 for easier apps experiment

##SBATCH --cpus-per-task 10     #set to 10 for full chimaira core per apk (60 GB ram)
##SBATCH --exclusive        #remove for easier apps experiment

# 2340 different test scenarios

taskName="hercules-sqlite"
localDir=/local/garbe
resultDir=~/sqlite
lastJobNo=2339

# Call this script as follows:
# sbatch slurm_pairwise.sh

echo =================================================================
echo % HERCULES SQLITE PAIRWISE\(s\)
echo % Task ID: ${SLURM_ARRAY_TASK_ID}
echo % JOB ID: ${SLURM_JOBID}
echo =================================================================

cd $localDir

cd TypeChef-SQLiteIfdeftoif
./parallel_pairwise.sh ${SLURM_ARRAY_TASK_ID} > $resultDir/chf_${SLURM_ARRAY_TASK_ID}.txt 2>&1

# send mail notification for last job
if [ ${SLURM_ARRAY_TASK_ID} -eq $lastJobNo ]; then
    echo "Stop slacking off." | mail -s "Chimaira job finished." fgarbe@fim.uni-passau.de
fi
