#!/usr/bin/env python3
"""
plot_ber.py - compare Verilog (RTL) BER results with theory and a floating-point
Monte-Carlo golden model.

  python python/plot_ber.py            (run from repo root, after the RTL sweep)

Eb/N0 for the RTL is derived from the integer noise sigma actually used:
      Eb/N0 = 16384 / (2*sigma^2)       (carrier amplitude 64, 8 samples/bit)
"""
import csv, os, sys
import numpy as np
from scipy.special import erfc
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

def qfunc(x): return 0.5 * erfc(x / np.sqrt(2))

def theory(ebn0_db):
    return qfunc(np.sqrt(2 * 10 ** (np.asarray(ebn0_db) / 10)))

def golden_model(ebn0_db, nsym=400_000, qpsk=False, seed=1):
    """Floating-point sample-level model mirroring the RTL (8 samples/symbol)."""
    rng = np.random.default_rng(seed)
    A, N = 64.0, 8
    n = np.arange(N)
    c, s = A * np.cos(2*np.pi*n/N), A * np.sin(2*np.pi*n/N)
    sigma = 128 / np.sqrt(2 * 10 ** (ebn0_db / 10))
    bi = rng.integers(0, 2, nsym) * 2 - 1
    bq = rng.integers(0, 2, nsym) * 2 - 1 if qpsk else np.zeros(nsym)
    tx = bi[:, None] * c + bq[:, None] * s
    rx = tx + rng.normal(0, sigma, tx.shape)
    di = np.sign(rx @ c)
    errs = np.sum(di != bi)
    bits = nsym
    if qpsk:
        dq = np.sign(rx @ s)
        errs += np.sum(dq != bq); bits *= 2
    return errs / bits

def main():
    path = "sim/ber_results.csv"
    if not os.path.exists(path):
        sys.exit("Run the Verilog sweep first (see README) -> sim/ber_results.csv")
    rows = list(csv.DictReader(open(path)))
    gain  = np.array([int(r["gain"]) for r in rows], float)
    ebn0  = 10 * np.log10(16384 / (2 * gain ** 2))
    bp    = np.array([int(r["bpsk_errs"]) / int(r["bpsk_bits"]) for r in rows])
    qp    = np.array([int(r["qpsk_errs"]) / int(r["qpsk_bits"]) for r in rows])

    print(f"{'Eb/N0[dB]':>9} {'BPSK RTL':>10} {'QPSK RTL':>10} {'Theory':>10}")
    for e, b, q in zip(ebn0, bp, qp):
        print(f"{e:9.2f} {b:10.2e} {q:10.2e} {theory(e):10.2e}")

    x = np.linspace(0, 11, 200)
    gm_b = [golden_model(e) for e in ebn0]
    gm_q = [golden_model(e, qpsk=True) for e in ebn0]

    os.makedirs("docs", exist_ok=True)
    plt.figure(figsize=(7.5, 5.2))
    plt.semilogy(x, theory(x), "k-", lw=1.5, label="Theory  Q(sqrt(2Eb/N0))")
    plt.semilogy(ebn0, np.where(bp > 0, bp, np.nan), "o", ms=8, mfc="none",
                 color="tab:blue", label="Verilog RTL - BPSK")
    plt.semilogy(ebn0, np.where(qp > 0, qp, np.nan), "s", ms=7, mfc="none",
                 color="tab:red", label="Verilog RTL - QPSK (per bit)")
    plt.semilogy(ebn0, gm_b, "--", color="tab:green", lw=1, label="Python golden model - BPSK")
    plt.semilogy(ebn0, gm_q, ":", color="tab:orange", lw=1.5, label="Python golden model - QPSK")
    plt.grid(True, which="both", alpha=.3)
    plt.xlabel("Eb/N0 (dB)"); plt.ylabel("Bit Error Rate")
    plt.title("FPGA transceiver: BER vs SNR over AWGN")
    plt.ylim(1e-6, 1); plt.xlim(0, 11); plt.legend(fontsize=8)
    plt.tight_layout(); plt.savefig("docs/ber_curve.png", dpi=150)
    print("saved docs/ber_curve.png")

if __name__ == "__main__":
    main()
