#!/usr/bin/env python3
"""Constellation diagrams (matched-filter outputs) for BPSK / QPSK at several SNRs."""
import numpy as np, os
import matplotlib; matplotlib.use("Agg")
import matplotlib.pyplot as plt

rng = np.random.default_rng(3)
A, N = 64.0, 8
n = np.arange(N); c = A*np.cos(2*np.pi*n/N); s = A*np.sin(2*np.pi*n/N)
E = c @ c

def run(ebn0_db, qpsk, nsym=3000):
    sigma = 128/np.sqrt(2*10**(ebn0_db/10))
    bi = rng.integers(0,2,nsym)*2-1
    bq = rng.integers(0,2,nsym)*2-1 if qpsk else np.zeros(nsym)
    rx = bi[:,None]*c + bq[:,None]*s + rng.normal(0,sigma,(nsym,N))
    return (rx@c)/E, (rx@s)/E

fig, ax = plt.subplots(2, 3, figsize=(11, 6.5))
for r, qpsk in enumerate([False, True]):
    for k, snr in enumerate([0, 5, 10]):
        i, q = run(snr, qpsk)
        ax[r,k].scatter(i, q, s=3, alpha=.5)
        ax[r,k].axhline(0, c="k", lw=.5); ax[r,k].axvline(0, c="k", lw=.5)
        ax[r,k].set_title(f"{'QPSK' if qpsk else 'BPSK'}  Eb/N0 = {snr} dB")
        ax[r,k].set_xlim(-2.5,2.5); ax[r,k].set_ylim(-2.5,2.5); ax[r,k].set_aspect("equal")
plt.tight_layout(); os.makedirs("docs", exist_ok=True)
plt.savefig("docs/constellations.png", dpi=140); print("saved docs/constellations.png")
