from pathlib import Path

from vunit import VUnit


ROOT = Path(__file__).resolve().parents[1]

vu = VUnit.from_argv(
    vhdl_standard="2008",
    compile_builtins=False,
)
vu.add_vhdl_builtins()

lib = vu.add_library("lib")

lib.add_source_file(str(ROOT / "rtl" / "alu.vhd"))
lib.add_source_file(str(ROOT / "tb" / "vunit" / "tb_alu_vunit.vhd"))

tb = lib.test_bench("tb_alu_vunit")

for width in (1, 4):
    tb.add_config(
        name=f"width_{width}",
        generics={"WIDTH_TB": width},
    )

vu.main()