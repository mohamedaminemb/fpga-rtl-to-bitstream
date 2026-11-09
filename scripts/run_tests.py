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
    ("sync_2ff", "tb_sync_2ff"),
    ("debouncer", "tb_debouncer"),
    ("button_conditioner", "tb_button_conditioner"),
    ("sequence_detector", "tb_sequence_detector"),
    ("traffic_light_controller", "tb_traffic_light_controller"),
    ("fifo_sync", "tb_fifo_sync"),
    ("uart_tx", "tb_uart_tx"),
    ("uart_rx", "tb_uart_rx"),
    ("uart_loopback", "tb_uart_loopback"),
    ("alu", "tb_alu"),
    ("uart_echo", "tb_uart_echo"),
]

source_overrides = {
    "uart_loopback": [
        "rtl/uart_tx.vhd",
        "rtl/uart_rx.vhd",
    ],
    "uart_echo": [
    "rtl/uart_rx.vhd",
    "rtl/fifo_sync.vhd",
    "rtl/uart_tx.vhd",
    "rtl/uart_echo.vhd",
],
}
simulation_options = {
    "alu": [
        [],                    
        ["-gWIDTH_TB=1"],
    ],
}

for module, testbench in tests:
    print(f"Testing {module}...", flush=True)

    sources = source_overrides.get(
        module,
        [f"rtl/{module}.vhd"],
    )

    run_command([
        "ghdl", "-a", "--std=08",
        *sources,
        f"tb/{testbench}.vhd",
    ])

    run_command([
        "ghdl", "-e", "--std=08", testbench,
    ])

    for options in simulation_options.get(module, [[]]):
        configuration = " ".join(options) or "default"
        print(f"  Configuration: {configuration}", flush=True)

        run_command([
            "ghdl", "-r", "--std=08", testbench,
            *options,
            "--assert-level=error",
       ])

    print(f"PASS: {module}", flush=True)

print(f"All {len(tests)} testbenches passed.", flush=True)