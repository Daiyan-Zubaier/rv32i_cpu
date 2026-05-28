#!/usr/bin/env python3
"""Run the rv32i_core simulation and profile the generated VCD."""

from __future__ import annotations

import argparse
import subprocess
import sys
from pathlib import Path
from typing import List, Optional


REPO_ROOT = Path(__file__).resolve().parents[1]
DEFAULT_VCD = REPO_ROOT / "waves" / "rv32i_core.vcd"


def run_checked(cmd: List[str]) -> None:
    print("+ " + " ".join(cmd), flush=True)
    subprocess.run(cmd, cwd=REPO_ROOT, check=True)


def build_arg_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Run rv32i_core with Verilator, then report CPI/IPC/latency stats.")
    program_group = parser.add_mutually_exclusive_group()
    program_group.add_argument("--program", type=Path, help="Existing Verilog hex file to load.")
    program_group.add_argument("--program-src", type=Path, help="Assembly source to build and load through make sim-program.")
    parser.add_argument("--cycles", type=int, help="Post-reset cycles to run. Requires the updated testbench plusarg support.")
    parser.add_argument("--clock-mhz", type=float, help="Optional target clock in MHz for instr/s estimates.")
    parser.add_argument("--idle-pc", action="append", default=[], help="PC to treat as idle/spin code.")
    parser.add_argument("--json", action="store_true", help="Print profiler JSON.")
    parser.add_argument("--trace", action="store_true", help="Include retired trace in the human report.")
    parser.add_argument("--skip-run", action="store_true", help="Only profile the existing VCD.")
    return parser


def make_args(args: argparse.Namespace) -> List[str]:
    if args.program_src is not None:
        cmd = ["make", "sim-program", f"PROGRAM_SRC={args.program_src}"]
    elif args.program is not None:
        cmd = ["make", "sim-core", f"PROGRAM={args.program}"]
    else:
        cmd = ["make", "sim-program"]

    sim_args: List[str] = []
    if args.cycles is not None:
        if args.cycles <= 0:
            raise ValueError("--cycles must be positive")
        sim_args.append(f"+cycles={args.cycles}")
    if sim_args:
        cmd.append("SIM_ARGS=" + " ".join(sim_args))
    return cmd


def profile_args(args: argparse.Namespace) -> List[str]:
    cmd = [sys.executable, "tools/profile_core.py", "--vcd", str(DEFAULT_VCD)]

    if args.program is not None:
        cmd.extend(["--program", str(args.program)])
    elif args.program_src is not None:
        cmd.extend(["--program", str(args.program_src.with_suffix(".hex"))])
    else:
        cmd.extend(["--program", "programs/smoke.hex"])

    if args.clock_mhz is not None:
        cmd.extend(["--clock-mhz", str(args.clock_mhz)])
    for pc in args.idle_pc:
        cmd.extend(["--idle-pc", pc])
    if args.json:
        cmd.append("--json")
    if args.trace:
        cmd.append("--trace")
    return cmd


def main(argv: Optional[List[str]] = None) -> int:
    parser = build_arg_parser()
    args = parser.parse_args(argv)

    try:
        if not args.skip_run:
            run_checked(make_args(args))
        run_checked(profile_args(args))
    except ValueError as exc:
        parser.error(str(exc))
    except subprocess.CalledProcessError as exc:
        return exc.returncode

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
