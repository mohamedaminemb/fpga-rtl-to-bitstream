import subprocess


def run_command(command):
    result = subprocess.run(command)

    if result.returncode != 0:
        raise SystemExit(result.returncode)


tests = [
    ("mux21", "tb_mux21"),
    ("adder_sub", "tb_adder_sub"),
    ("reg_en", "tb_reg_en"),
    ("counter_en", "tb_counter_en"),
    ("clock_enable", "tb_clock_enable"),
    ("edge_detector", "tb_edge_detector"),
]

for module, testbench in tests:
    print(f"Testing {module}...", flush=True)

    run_command([
        "ghdl", "-a", "--std=08",
        f"rtl/{module}.vhd",
        f"tb/{testbench}.vhd",
    ])

    run_command([
        "ghdl", "-e", "--std=08", testbench,
    ])

    run_command([
        "ghdl", "-r", "--std=08", testbench,
        "--assert-level=error",
    ])

    print(f"PASS: {module}", flush=True)

print(f"All {len(tests)} testbenches passed.", flush=True)