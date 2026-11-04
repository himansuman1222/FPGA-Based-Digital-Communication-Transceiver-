# Design notes

## Sample-level signal model
* fs = clock, 8 samples/symbol, carrier fc = fs/8 (one full cycle per symbol)
* Carrier LUT: `c[n] = 64cos(2πn/8)`, `s[n] = 64sin(2πn/8)` (8-bit signed)
* BPSK: `s[n] = (2b-1)·c[n]` QPSK: `s[n] = (2bI-1)·c[n] + (2bQ-1)·s[n]`
* Channel: `r[n] = s[n] + w[n]`, `w ~ N(0, σ²)` (σ in LSBs = `noise_gain`)

## Coherent demodulation (integrate & dump)
`y = Σ_{n=0..7} r[n]·c[n]`, decision = sign(y).
Mean `|y| = Σc² = 16384`, noise variance `σ²·16384`.

## SNR mapping
`Eb = Σc² = 16384`, `N0 = 2σ²`  ⇒  `Eb/N0 = 16384 / (2σ²)`  ⇒  `σ = 128/√(2·Eb/N0)`

| Eb/N0 (dB) | 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 |
|---|---|---|---|---|---|---|---|---|---|---|---|
| gain (σ)   | 91 | 81 | 72 | 64 | 57 | 51 | 45 | 40 | 36 | 32 | 29 |

## Theory
`BER_BPSK = Q(√(2Eb/N0))`. QPSK with Gray mapping has the **same BER per bit**
(I and Q are orthogonal), but sends 2 bits per symbol → 2× spectral efficiency
at the same bandwidth.

## AWGN generator
12 uniform bytes (3× xorshift32) summed (Central Limit Theorem) → σ_raw = 256,
scaled by `gain/256`. Fully synthesizable, 1 sample/clock.

## Pipeline (both transceivers)
`stage0` timing/PRBS → `stage1` modulator → `stage2` +AWGN → `stage3` mixer
→ `stage4` accumulator + decision/BER counters. Tx bits are delay-matched to
the receiver so BER compares aligned bits.
