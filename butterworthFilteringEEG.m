function [outputArg1] = butterworthFilteringEEG(name, electrode, N)
%Funkcija za filtriranje očesnih artefaktov prek
%butterworthovega filtra
% FP1 = 22, FP2 = 23, FPZ = 24
    [sigs, freq, tm] = rdsamp(name, 1:64);
% bandpass filter, filtriranje brez faznega zamika
    [b, a] = butter(5, [0.1 30]/(freq/2));
    filtered = filtfilt(b, a, sigs(:, electrode));

    figure;
    tiledlayout(4,1)
    nexttile
    plot(tm, sigs(:,electrode))
    lims = ylim;
    ylim1 = lims(1);
    ylim2 = lims(2);
    title('Original signal')
    nexttile
    plot(tm, filtered)
    ylim([ylim1 ylim2])
    title('Filtered signal')
    % okolica točk nad pragom se postavi na 0
    prag = input("Input treshold value(int): ");
    side = floor(N/2);
    for i=1:length(filtered)
        if abs(filtered(i)) > prag
            for j=(i-side):(i+side)
                if j > 0 && j <= length(filtered)
                    filtered(j) = 0;
                end
            end
        end
    end
    nexttile
    plot(tm, filtered)
    ylim([ylim1 ylim2])
    xlims = xlim;
    title("Tresholded signal")

% vse ničelne vrednosti se izločijo
    filtered = filtered';
    filteredRemoved = [];
    for i=1:length(filtered)
        if filtered(i) ~= 0
            filteredRemoved = [filteredRemoved filtered(i)];
        end
    end

    nexttile
    plot(tm(1:length(filteredRemoved)), filteredRemoved)
    ylim([ylim1 ylim2])
    xlim([xlims(1) xlims(2)])
    title('Final signal')

% prikaz frekvenc s Fourierjevo transformacijo
    outputArg1 = filteredRemoved;
    figure;
    tiledlayout(2,1)
    nexttile
    [xo, yo] = ddrawfreqs(sigs(:, electrode));
    [xf, yf] = ddrawfreqs(filteredRemoved);
    plot(xo, yo)
    title('Frequency space of original signal')
    ylims = ylim;
    xlims = xlim;
    nexttile
    plot(xf, yf)
    ylim([ylims(1) ylims(2)])
    xlim([xlims(1) xlims(2)])
    title('Frequency space of final signal')
end

function [x, y] = ddrawfreqs(sample)
% FP1 = 21, FP2 = 23, FPZ = 22
    len = length(sample);
    nfft = 2^nextpow2(len);
    f = 160/2 * linspace(0,1,nfft/2+1);
    ftc = fft(sample, nfft)/len;
    x = f;
    y = 2*abs(ftc(1:nfft/2+1));
end