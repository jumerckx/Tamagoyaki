#!/usr/bin/env python3
import subprocess
import sys
import os
import re

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
    subprocess.run(['circt-synth','--analysis-output=rover-mlir/results', os.path.join(output_dir, 'converted.mlir'), '-o', os.path.join(output_dir, 'synthesized.mlir')],check=True)
    subprocess.run(['circt-translate','--export-aiger', os.path.join(output_dir, 'synthesized.mlir'), '-o', os.path.join(output_dir, 'synthesized.aig')],check=True)
    run(f'abc -c "read_genlib ../../rtl/DatapathBench/libraries/asap7.genlib; read {os.path.join(output_dir, 'synthesized.aig')}; strash; map; print_stats" > {os.path.join(output_dir, 'abc_stats.txt')}')

    abc_area = grep_stat(f"{os.path.join(output_dir, 'abc_stats.txt')}", r'area =+([0-9.]+)')
    abc_delay = grep_stat(f"{os.path.join(output_dir, 'abc_stats.txt')}", r'delay =+([0-9.]+)')
    print(f"{name}: Area={abc_area}, Delay={abc_delay}")
    
def run_comparison(benchmark_filenames):
    # Paths

    root_dir = os.getcwd()
    for benchmark_filename in benchmark_filenames:
        print(benchmark_filename)
        input_file = os.path.join(root_dir, 'rover-mlir', 'benchmarks', benchmark_filename)
        rover_patterns = os.path.join(root_dir, 'rover-mlir', 'benchmarks', 'rover.pdl_interp.mlir')
        tamago_patterns = os.path.join(root_dir, 'rover-mlir', 'benchmarks', 'tamago.pdl_interp.mlir')
        output_dir = os.path.join(root_dir, 'rover-mlir/results')
        os.makedirs(output_dir, exist_ok=True)

        # Run circt-synth on input file
        # print("Running circt-synth...")
        run_circt_synth("circt-synth", input_file, output_dir)
        subprocess.run(['emeraude-mlir-opt', '--func-to-hw-module', '--allow-unregistered-dialect', '-o', os.path.join(output_dir, 'converted.mlir'), input_file], check=True)
        subprocess.run(['circt-synth','--analysis-output=rover-mlir/results', os.path.join(output_dir, 'converted.mlir'), '-o', os.path.join(output_dir, 'synthesized.mlir')],check=True)
        subprocess.run(['circt-translate','--export-aiger', os.path.join(output_dir, 'synthesized.mlir'), '-o', os.path.join(output_dir, 'synthesized.aig')],check=True)
        run(f'abc -c "read_genlib ../../rtl/DatapathBench/libraries/asap7.genlib; read {os.path.join(output_dir, 'synthesized.aig')}; strash; map; print_stats" > {os.path.join(output_dir, 'abc_stats.txt')}')

        abc_area = grep_stat(f"{os.path.join(output_dir, 'abc_stats.txt')}", r'area =+([0-9.]+)')
        abc_delay = grep_stat(f"{os.path.join(output_dir, 'abc_stats.txt')}", r'delay =+([0-9.]+)')
        print(f"circt-synth: Area={abc_area}, Delay={abc_delay}")
        return
        # ROVER!
        # Now run the full pipeline
        # print("Running pipeline...")
        cmd1 = [
            os.path.join(root_dir, 'build', 'bin', 'rover-mlir-opt'),
            f'--rover-saturate=patterns-file={rover_patterns} max-iters=4',
            '--remove-dead-values',
            input_file,
            '--mlir-print-op-generic'
        ]

        cmd2 = ['circt-opt', '--canonicalize', '--allow-unregistered-dialect', '--comb-int-range-narrowing']

        cmd3 = [
            os.path.join(root_dir, 'build', 'bin', 'rover-mlir-opt'),
            '--rover-extract=delay',
            '--mlir-print-op-generic'
        ]
        cmd4 = ['emeraude-mlir-opt', '--func-to-hw-module', '--allow-unregistered-dialect']

        cmd5 = ['circt-synth', '--format=mlir', '--analysis-output=rover-mlir/results', '-o', os.path.join(output_dir, 'synthesized.mlir')]

        # Run pipeline
        p1 = subprocess.Popen(cmd1, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        # p2 = subprocess.Popen(cmd2, stdin=p1.stdout, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        p3 = subprocess.Popen(cmd3, stdin=p1.stdout, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        p4 = subprocess.Popen(cmd4, stdin=p3.stdout, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        p5 = subprocess.Popen(cmd5, stdin=p4.stdout, stdout=subprocess.PIPE, stderr=subprocess.PIPE)


        # Close the stdout of p1 to allow p2 to receive SIGPIPE if p1 exits
        p1.stdout.close()

        # Get output
        output, error = p5.communicate()

        # Check for errors
        if p1.returncode and p1.returncode != 0:
            print(f"Error in first command: {error.decode()}")
            return
        # if p2.returncode and p2.returncode != 0:
        #     print(f"Error in second command: {error.decode()}")
        #     return
        if p3.returncode and p3.returncode != 0:
            print(f"Error in third command: {error.decode()}")
            return
        if p4.returncode and p4.returncode != 0:
            print(f"Error in fourth command: {error.decode()}")
            return
        if p5.returncode and p5.returncode != 0:
            print(f"Error in fifth command: {error.decode()}")
            return

        # print(f"rover-synth: and_inv={and_inv}, delay={delay}")

        subprocess.run(['circt-translate','--export-aiger', os.path.join(output_dir, 'synthesized.mlir'), '-o', os.path.join(output_dir, 'synthesized.aig')],check=True)
        run(f'abc -c "read_genlib ../../rtl/DatapathBench/libraries/asap7.genlib; read {os.path.join(output_dir, 'synthesized.aig')}; strash; map; print_stats" > {os.path.join(output_dir, 'abc_stats.txt')}')

        abc_area = grep_stat(f"{os.path.join(output_dir, 'abc_stats.txt')}", r'area =+([0-9.]+)')
        abc_delay = grep_stat(f"{os.path.join(output_dir, 'abc_stats.txt')}", r'delay =+([0-9.]+)')
        print(f"rover-synth: Area={abc_area}, Delay={abc_delay}")


        # TAMAGOYAKI!
        # Now run the full pipeline
        # print("Running pipeline...")
        cmd1 = [
            os.path.join(root_dir, 'build', 'bin', 'rover-mlir-opt'),
            f'--rover-saturate=patterns-file={tamago_patterns} max-iters=4',
            '--remove-dead-values',
            input_file,
            '--mlir-print-op-generic'
        ]

        cmd2 = ['circt-opt', '--canonicalize', '--allow-unregistered-dialect', '--comb-int-range-narrowing']

        cmd3 = [
            os.path.join(root_dir, 'build', 'bin', 'rover-mlir-opt'),
            '--rover-extract=delay',
            '--mlir-print-op-generic'
        ]
        cmd4 = ['emeraude-mlir-opt', '--func-to-hw-module', '--allow-unregistered-dialect']

        cmd5 = ['circt-synth', '--format=mlir', '--analysis-output=rover-mlir/results', '-o', os.path.join(output_dir, 'synthesized.mlir')]

        # Run pipeline
        p1 = subprocess.Popen(cmd1, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        p2 = subprocess.Popen(cmd2, stdin=p1.stdout, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        p3 = subprocess.Popen(cmd3, stdin=p2.stdout, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        p4 = subprocess.Popen(cmd4, stdin=p3.stdout, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        p5 = subprocess.Popen(cmd5, stdin=p4.stdout, stdout=subprocess.PIPE, stderr=subprocess.PIPE)


        # Close the stdout of p1 to allow p2 to receive SIGPIPE if p1 exits
        p1.stdout.close()

        # Get output
        output, error = p5.communicate()

        # Check for errors
        if p1.returncode and p1.returncode != 0:
            print(f"Error in first command: {error.decode()}")
            return
        if p2.returncode and p2.returncode != 0:
            print(f"Error in second command: {error.decode()}")
            return
        if p3.returncode and p3.returncode != 0:
            print(f"Error in third command: {error.decode()}")
            return
        if p4.returncode and p4.returncode != 0:
            print(f"Error in fourth command: {error.decode()}")
            return
        if p5.returncode and p5.returncode != 0:
            print(f"Error in fifth command: {error.decode()}")
            return

        # print(f"rover-synth: and_inv={and_inv}, delay={delay}")

        subprocess.run(['circt-translate','--export-aiger', os.path.join(output_dir, 'synthesized.mlir'), '-o', os.path.join(output_dir, 'synthesized.aig')],check=True)
        run(f'abc -c "read_genlib ../../rtl/DatapathBench/libraries/asap7.genlib; read {os.path.join(output_dir, 'synthesized.aig')}; strash; map; print_stats" > {os.path.join(output_dir, 'abc_stats.txt')}')

        abc_area = grep_stat(f"{os.path.join(output_dir, 'abc_stats.txt')}", r'area =+([0-9.]+)')
        abc_delay = grep_stat(f"{os.path.join(output_dir, 'abc_stats.txt')}", r'delay =+([0-9.]+)')
        print(f"tamag-synth: Area={abc_area}, Delay={abc_delay}")

if __name__ == "__main__":

    if len(sys.argv) < 2:
        benchmark_filename = ["FirFilter.mlir", "AdpcmDecoder.mlir", "ShiftedFma.mlir", "ShiftedFmaNonUnif.mlir", "ShiftMult.mlir", "MulSel.mlir", "MulSelNonUnif.mlir"]
    else:
        benchmark_filename = [sys.argv[1]]
    run_comparison(benchmark_filename)