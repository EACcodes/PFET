#!/bin/bash
#SBATCH --nodes=1 
#SBATCH --ntasks-per-node=2
#SBATCH -t 96:00:00
#SBATCH --job-name=h4_emb_2
#SBATCH --output=h4-total
#SBATCH --mem-per-cpu=12000
#SBATCH --error=JobName-%j.err



python test-ao.py 
