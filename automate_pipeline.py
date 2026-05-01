#!/usr/bin/env python3
import string
import subprocess
import sys
import os
import re
import time

def run(cmd, stdout=None):
    """Run a shell command and optionally redirect stdout."""
    if stdout:
        with open(stdout, 'w') as f:
            subprocess.run(cmd, shell=True, stdout=f, stderr=subprocess.STDOUT)
    else:
        subprocess.run(cmd, shell=True, check=True)

def grep_stat(filename, pattern, group=1):
    """Extract a number from a file using a regex pattern."""
    with open(filename) as f:
        for line in f:
            m = re.search(pattern, line)
            if m:
                return m.group(group)
    return ""

def run_circt_synth(name, input_file, output_dir):
    subprocess.run(['emeraude-mlir-opt', '--func-to-hw-module', '--allow-unregistered-dialect', '-o', os.path.join(output_dir, 'converted.mlir'), input_file], check=True)
    subprocess.run(['circt-synth',f'--analysis-output=rover-mlir/results/{name}', os.path.join(output_dir, 'converted.mlir'), '-o', os.path.join(output_dir, 'synthesized.mlir')],check=True)
    subprocess.run(['circt-translate','--export-aiger', os.path.join(output_dir, 'synthesized.mlir'), '-o', os.path.join(output_dir, 'synthesized.aig')],check=True)
    subprocess.run(f"abc -c \"read_genlib ../../rtl/DatapathBench/libraries/asap7.genlib; read {os.path.join(output_dir, 'synthesized.aig')}; strash; map; print_stats\" > {os.path.join(output_dir, 'abc_stats.txt')}", shell=True)

    abc_area = grep_stat(f"{os.path.join(output_dir, 'abc_stats.txt')}", r'area =+([0-9.]+)')
    abc_delay = grep_stat(f"{os.path.join(output_dir, 'abc_stats.txt')}", r'delay =+([0-9.]+)')
    return round(float(abc_area)), round(float(abc_delay))
    
def run_comparison(benchmark_filenames):
    # Paths

    root_dir = os.getcwd()
    for benchmark_filename in benchmark_filenames:
        # print(benchmark_filename)
        input_file = os.path.join(root_dir, 'rover-mlir', 'benchmarks', benchmark_filename)
        rover_patterns = os.path.join(root_dir, 'rover-mlir', 'benchmarks', 'rover.pdl_interp.mlir')
        tamago_patterns = os.path.join(root_dir, 'rover-mlir', 'benchmarks', 'tamago.pdl_interp.mlir')
        output_dir = os.path.join(root_dir, 'rover-mlir/results')
        os.makedirs(output_dir, exist_ok=True)

        # CIRCT SYNTH BASELINE
        (circt_area, circt_delay) = run_circt_synth("circt-synth", input_file, output_dir)

        # SINGLE ----------------------------------------------------------------
        rover_mlir = os.path.join(output_dir, 'rover_synth.mlir')
        rover = subprocess.run([
            os.path.join(root_dir, 'build', 'bin', 'rover-mlir-opt'),
            f'--rover-saturate=patterns-file={rover_patterns} max-iters=4',
            '--rover-extract=delay',
            '--remove-dead-values',
            input_file,
            '--mlir-print-op-generic',
            '--mlir-timing',
            '-o',
            rover_mlir,
        ], check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)

        # print(rover.stderr)

        pattern = r'(\d+\.\d+)\s*\([^)]+\)\s*RoverSaturatePass'
        match = re.search(pattern, rover.stderr)  # Search in stderr instead of stdout
        rover_time = 0.0
        if match:
            rover_time = float(match.group(1))
        (rover_area, rover_delay) = run_circt_synth("rover-synth", rover_mlir, output_dir)
        
        # MULTI ----------------------------------------------------------------
        start_time = time.time()
        multi = subprocess.run([
            os.path.join(root_dir, 'build', 'bin', 'rover-mlir-opt'),
            f'--rover-saturate=patterns-file={tamago_patterns} max-iters=4',
            '--remove-dead-values',
            input_file,
            '-o',
            os.path.join(output_dir, 'multi_synth_egraph.mlir'),
            '--mlir-print-op-generic',
            '--mlir-timing'
        ], check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)

        # print(multi.stderr)

        match = re.search(pattern, multi.stderr)  # Search in stderr instead of stdout
        multi_time = 0.0
        if match:
            multi_time = float(match.group(1))

        subprocess.run([
            os.path.join(root_dir, 'build', 'bin', 'rover-mlir-opt'),
            '--rover-extract=delay',
            '--mlir-print-op-generic',
            os.path.join(output_dir, 'multi_synth_egraph.mlir'),
            '-o',
            os.path.join(output_dir, 'multi_synth.mlir')
        ], check=True)
        
        (multi_area, multi_delay) = run_circt_synth("multi-synth", os.path.join(output_dir, 'multi_synth.mlir'), output_dir)

        # MULTI PERSIST --------------------------------------------------------
        start_time = time.time()
        subprocess.run([
            os.path.join(root_dir, 'build', 'bin', 'rover-mlir-opt'),
            f'--rover-saturate=patterns-file={tamago_patterns} max-iters=4',
            '--remove-dead-values',
            input_file,
            '-o',
            os.path.join(output_dir, 'multi_persist_synth_egraph.mlir'),
            '--mlir-print-op-generic'
        ], check=True)
        
        persist_circt = subprocess.run(['circt-opt', '--canonicalize', '--allow-unregistered-dialect', '--comb-int-range-narrowing', os.path.join(output_dir, 'multi_persist_synth_egraph.mlir'), '-o', os.path.join(output_dir, 'multi_persist_synth_egraph_canon.mlir'), '--mlir-timing'], check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        
        multi_persist_time = multi_time

        pattern = r'(\d+\.\d+)\s*\([^)]+\)\s*Canonicalizer'
        match = re.search(pattern, persist_circt.stderr)  # Search in stderr instead of stdout
        if match:
            multi_persist_time += float(match.group(1))

        pattern = r'(\d+\.\d+)\s*\([^)]+\)\s*CombIntRangeNarrowing'
        match = re.search(pattern, persist_circt.stderr)  # Search in stderr instead of stdout
        if match:
            multi_persist_time += float(match.group(1))

        subprocess.run([
            os.path.join(root_dir, 'build', 'bin', 'rover-mlir-opt'),
            '--rover-extract=delay',
            '--mlir-print-op-generic',
            os.path.join(output_dir, 'multi_persist_synth_egraph_canon.mlir'),
            '-o',
            os.path.join(output_dir, 'multi_persist_synth.mlir')
        ], check=True)
        
        (multi_persist_area, multi_persist_delay) = run_circt_synth("multi-synth", os.path.join(output_dir, 'multi_persist_synth.mlir'), output_dir)

        min_area = min(circt_area, rover_area, multi_area, multi_persist_area)
        min_delay = min(circt_delay, rover_delay, multi_delay, multi_persist_delay)
        if circt_area == min_area: 
            circt_area = f"\\textbf{{ {circt_area} }}"
        if rover_area == min_area: 
            rover_area = f"\\textbf{{ {rover_area} }}"
        if multi_area == min_area: 
            multi_area = f"\\textbf{{ {multi_area} }}"
        if multi_persist_area == min_area:
            multi_persist_area = f"\\textbf{{ {multi_persist_area} }}"

        if circt_delay == min_delay:
            circt_delay = f"\\textbf{{ {circt_delay} }}"
        if rover_delay == min_delay:
            rover_delay = f"\\textbf{{ {rover_delay} }}"
        if multi_delay == min_delay:
            multi_delay = f"\\textbf{{ {multi_delay} }}"
        if multi_persist_delay == min_delay:
            multi_persist_delay = f"\\textbf{{ {multi_persist_delay} }}"

        rover_time = int(rover_time * 1000)
        multi_time = int(multi_time * 1000)
        multi_persist_time = int(multi_persist_time * 1000)
        print(f"{benchmark_filename} & {circt_area} & {circt_delay} & {rover_area} & {rover_delay}& {rover_time} & {multi_area} & {multi_delay} & {multi_time} & {multi_persist_area} & {multi_persist_delay} & {multi_persist_time} \\\\")

if __name__ == "__main__":

    if len(sys.argv) < 2:
        benchmark_filename = ["FirFilter.mlir", "AdpcmDecoder.mlir", "ShiftedFma.mlir", "ShiftMult.mlir"]
    else:
        benchmark_filename = [sys.argv[1]]
    run_comparison(benchmark_filename)