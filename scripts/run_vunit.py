from pathlib import Path

from vunit import VUnit


ROOT = Path(__file__).resolve().parents[1]

vu = VUnit.from_argv(
    vhdl_standard="2008",
    compile_builtins=False,
)
vu.add_vhdl_builtins()

lib = vu.add_library("lib")

# Sources ALU.
lib.add_source_file(str(ROOT / "rtl" / "alu.vhd"))
lib.add_source_file(
    str(ROOT / "tb" / "vunit" / "tb_alu_vunit.vhd")
)

# Sources FIFO.
lib.add_source_file(str(ROOT / "rtl" / "fifo_sync.vhd"))
lib.add_source_file(
    str(ROOT / "tb" / "vunit" / "tb_fifo_sync_vunit.vhd")
)

# ALU : chaque scénario est exécuté sur deux largeurs.
alu_tb = lib.test_bench("tb_alu_vunit")

for width in (1, 4):
    alu_tb.add_config(
        name=f"width_{width}",
        generics={"WIDTH_TB": width},
    )

# FIFO : adapter les profondeurs au scénario.
fifo_tb = lib.test_bench("tb_fifo_sync_vunit")

partial_depth_tests = {
    "simultaneous_when_partial",
    "wraparound_with_remaining_data",
}

for test in fifo_tb.get_tests():
    if test.name in partial_depth_tests:
        depths = (3, 4)
    else:
        depths = (1, 3, 4)

    for depth in depths:
        test.add_config(
            name=f"depth_{depth}",
            generics={
                "WIDTH_TB": 8,
                "DEPTH_TB": depth,
            },
        )
        
for module in ("uart_rx", "uart_tx", "uart_echo"):
    lib.add_source_file(str(ROOT / "rtl" / f"{module}.vhd"))

lib.add_source_file(
    str(ROOT / "tb" / "vunit" / "tb_uart_echo_vunit.vhd")
)

echo_tb = lib.test_bench("tb_uart_echo_vunit")



for test in echo_tb.get_tests():
    if test.name in ("overflow_sticky", "reset_recovery"):
        depths = (1,)
    else:
        depths = (1, 3, 4)

    for depth in depths:
        test.add_config(
            name=f"depth_{depth}",
            generics={"FIFO_DEPTH_TB": depth},
        )

vu.main()