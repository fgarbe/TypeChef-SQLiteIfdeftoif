#!/bin/bash

sbatch -A spl --cpus-per-task=1 -p chimaira --time=00:10:00 -o /home/garbe/logs/publish.txt force_chimaira.sh

# echo "Stop slacking off." | mail -s "Chimaira update finished." fgarbe@fim.uni-passau.de