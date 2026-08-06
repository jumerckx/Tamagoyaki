#!/usr/bin/env python3
import csv
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

    eclasses = {"rover": [], "multi": [], "multi_persist": []}
    enodes = {"rover": [], "multi": [], "multi_persist": []}

    # Extract graph stats from ematch debug output for any iteration.
    iter_pat = re.compile(
        r"Graph has\s+(\d+)\s+e-classes\s+and\s+(\d+)\s+e-nodes\s+\(iteration\s+(\d+)\)\."
    )

    def append_latest_iter_stats(name, stderr_text):
        matches = list(iter_pat.finditer(stderr_text))
        if matches:
            best_match = max(matches, key=lambda m: int(m.group(3)))
            eclasses[name].append(int(best_match.group(1)))
            enodes[name].append(int(best_match.group(2)))
        else:
            eclasses[name].append(None)
            enodes[name].append(None)

    root_dir = os.getcwd()
    csv_path = os.path.join(root_dir, 'rover-mlir', 'results', 'egraph_comparisons.csv')
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
            '--debug-only=ematch',
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
        append_latest_iter_stats("rover", rover.stderr)
        (rover_area, rover_delay) = run_circt_synth("rover-synth", rover_mlir, output_dir)
        
        # MULTI ----------------------------------------------------------------
        start_time = time.time()
        multi = subprocess.run([
            os.path.join(root_dir, 'build', 'bin', 'rover-mlir-opt'),
            f'--rover-saturate=patterns-file={tamago_patterns} max-iters=4',
            '--remove-dead-values',
            '--debug-only=ematch',
            input_file,
            '-o',
            os.path.join(output_dir, 'multi_synth_egraph.mlir'),
            '--mlir-print-op-generic',
            '--mlir-timing'
        ], check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)

        append_latest_iter_stats("multi", multi.stderr)

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
        multi_persist = subprocess.run([
            os.path.join(root_dir, 'build', 'bin', 'rover-mlir-opt'),
            f'--rover-saturate=patterns-file={tamago_patterns} max-iters=4',
            '--remove-dead-values',
            '--debug-only=ematch',
            input_file,
            '-o',
            os.path.join(output_dir, 'multi_persist_synth_egraph.mlir'),
            '--mlir-print-op-generic'
        ], check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        append_latest_iter_stats("multi_persist", multi_persist.stderr)
        
        persist_circt = subprocess.run(['circt-opt', '--canonicalize', '--allow-unregistered-dialect', '--comb-int-range-narrowing', os.path.join(output_dir, 'multi_persist_synth_egraph.mlir'), '-o', os.path.join(output_dir, 'multi_persist_synth_egraph_canon.mlir'), '--mlir-timing'], check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        
        multi_persist_time = multi_time

        multi_persist = subprocess.run([
            os.path.join(root_dir, 'build', 'bin', 'rover-mlir-opt'),
            f'--rover-saturate=patterns-file={tamago_patterns} max-iters=0',
            '--remove-dead-values',
            '--debug-only=ematch',
            os.path.join(output_dir, 'multi_persist_synth_egraph.mlir'),
            '-o',
            os.path.join(output_dir, 'tmp.mlir'),
            '--mlir-print-op-generic'
        ], check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        append_latest_iter_stats("multi_persist", multi_persist.stderr)

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

    print("\nE-graph change summary at latest matched iteration")
    print(
        "benchmark & rover_eclasses & multi_eclasses & multi_persist_eclasses & "
        "rover_to_multi_eclasses & multi_to_multi_persist_eclasses & "
        "rover_enodes & multi_enodes & multi_persist_enodes & "
        "rover_to_multi_enodes & multi_to_multi_persist_enodes"
    )

    csv_rows = []
    for i, benchmark_filename in enumerate(benchmark_filenames):
        rover_ec = eclasses["rover"][i]
        multi_ec = eclasses["multi"][i]
        persist_ec = eclasses["multi_persist"][i]
        rover_en = enodes["rover"][i]
        multi_en = enodes["multi"][i]
        persist_en = enodes["multi_persist"][i]

        delta_ec_rover_to_multi = (
            multi_ec - rover_ec
            if rover_ec is not None and multi_ec is not None
            else "NA"
        )
        delta_ec_multi_to_persist = (
            persist_ec - multi_ec
            if multi_ec is not None and persist_ec is not None
            else "NA"
        )
        delta_en_rover_to_multi = (
            multi_en - rover_en
            if rover_en is not None and multi_en is not None
            else "NA"
        )
        delta_en_multi_to_persist = (
            persist_en - multi_en
            if multi_en is not None and persist_en is not None
            else "NA"
        )

        rover_ec_str = rover_ec if rover_ec is not None else "NA"
        multi_ec_str = multi_ec if multi_ec is not None else "NA"
        persist_ec_str = persist_ec if persist_ec is not None else "NA"
        rover_en_str = rover_en if rover_en is not None else "NA"
        multi_en_str = multi_en if multi_en is not None else "NA"
        persist_en_str = persist_en if persist_en is not None else "NA"

        csv_rows.append([
            benchmark_filename,
            rover_ec_str,
            multi_ec_str,
            persist_ec_str,
            delta_ec_rover_to_multi,
            delta_ec_multi_to_persist,
            rover_en_str,
            multi_en_str,
            persist_en_str,
            delta_en_rover_to_multi,
            delta_en_multi_to_persist,
        ])

        print(
            f"{benchmark_filename} & {rover_ec_str} & {multi_ec_str} & {persist_ec_str} & "
            f"{delta_ec_rover_to_multi} & {delta_ec_multi_to_persist} & "
            f"{rover_en_str} & {multi_en_str} & {persist_en_str} & "
            f"{delta_en_rover_to_multi} & {delta_en_multi_to_persist} \\\\" 
        )

    os.makedirs(os.path.dirname(csv_path), exist_ok=True)
    with open(csv_path, 'w', newline='') as csv_file:
        writer = csv.writer(csv_file)
        writer.writerow([
            'benchmark',
            'rover_eclasses',
            'multi_eclasses',
            'multi_persist_eclasses',
            'rover_to_multi_eclasses',
            'multi_to_multi_persist_eclasses',
            'rover_enodes',
            'multi_enodes',
            'multi_persist_enodes',
            'rover_to_multi_enodes',
            'multi_to_multi_persist_enodes',
        ])
        writer.writerows(csv_rows)

    print(f"Wrote e-graph comparison CSV: {csv_path}")

if __name__ == "__main__":

    if len(sys.argv) < 2:
        benchmark_filename = ["FirFilter.mlir", "AdpcmDecoder.mlir", "ShiftedFma.mlir", "ShiftMult.mlir"]
    else:
        benchmark_filename = [sys.argv[1]]
    run_comparison(benchmark_filename)