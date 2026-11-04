% ber_analysis.m - MATLAB counterpart of python/plot_ber.py
% Reads sim/ber_results.csv produced by the Verilog testbench and compares the
% measured BER with theory:  BER = Q(sqrt(2*Eb/N0)) = 0.5*erfc(sqrt(Eb/N0))
T     = readtable('sim/ber_results.csv');
sigma = T.gain;                                  % noise sigma in LSBs
ebn0  = 10*log10(16384 ./ (2*sigma.^2));         % Eb/N0 (dB)
ber_b = T.bpsk_errs ./ T.bpsk_bits;
ber_q = T.qpsk_errs ./ T.qpsk_bits;

x   = linspace(0, 11, 200);
th  = 0.5*erfc(sqrt(10.^(x/10)));

figure; semilogy(x, th, 'k-', 'LineWidth', 1.5); hold on; grid on;
semilogy(ebn0, ber_b, 'bo', 'MarkerSize', 8);
semilogy(ebn0, ber_q, 'rs', 'MarkerSize', 7);
xlabel('E_b/N_0 (dB)'); ylabel('Bit Error Rate');
legend('Theory','RTL BPSK','RTL QPSK (per bit)'); ylim([1e-6 1]);
title('FPGA transceiver BER vs SNR (AWGN)');

% ---- floating-point BPSK Monte-Carlo (independent check) ----
N = 1e6; snr = 0:10; ber_mc = zeros(size(snr));
for k = 1:numel(snr)
    b  = randi([0 1], N, 1)*2-1;
    r  = b + randn(N,1)/sqrt(2*10^(snr(k)/10));
    ber_mc(k) = mean(sign(r) ~= b);
end
semilogy(snr, ber_mc, 'g--');
