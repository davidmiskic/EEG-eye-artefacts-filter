function [outputArg1] = ICAfilteringEEG(name)
%Funkcija za filtriranje očesnih artefaktov  prek postopka
%analize neodvisnih komponent
    [sig, freq, tm] = rdsamp(name, 1:64);
    sig = sig';
% neodvisne komponente, mešalna matrika A, ločevalna matrika W (inverz mešalne)
% aproksimacija signala Y = inv(W) * icasig
% izbira raznih komponent Yn = Winv(:, subset)*icasig(subset, :)
    disp("computing ICA...")
    [icasig, A, W] = fastica(sig, 'verbose', 'off');
    while diff(size(W)) ~= 0
        disp("ICA did not converge, W is not square. Trying again.")
        [icasig, A, W] = fastica(sig, 'verbose', 'off');
    end
% plot(tm, icasig(3, :)) je 3-ta komponenta
% pokaži 15 komponent na okno
    warning('off', 'signal:findpeaks:largeMinPeakHeight');

    peakCnt = [];
    ylms = [min(icasig(:)) max(icasig(:))];
    floorStart = -2;
    for i=1:size(icasig, 1)
        if floor((i-1)/15) ~= floorStart
            figure;
            tiledlayout(5,3)
            floorStart = floor(i/15);
            %disp("processing " + (floorStart+1) + "/" + 5)
        end
        x = findpeaks(abs(icasig(i,:)), 'MinPeakHeight', 5);
        peakCnt = [peakCnt length(x)];
        
        nexttile;
        plot(tm, icasig(i,:));
        ylim([ylms(1) ylms(2)]);
        title(i)
    end

    maxPeak = max(peakCnt);
    peaksSorted = sort(peakCnt,'descend');
    indexes = [];
    disp("-->Recommended to select following components: ")

    for i=1:length(peaksSorted)
        if peaksSorted(i) > maxPeak/2
            ind = find(peakCnt == peaksSorted(i), 1);
            disp("Component number " + ind + " with " + peaksSorted(i) + " peaks")
            indexes = [indexes ind];
            peakCnt(ind) = 0;
        end
    end

% uporabnik izbere, če bi kako komponento odstranil
    unselection = input("-->Choose components that will NOT be included in vector format [..]! ");
    selection = [];
    for i=1:64
        if sum(ismember(unselection, i)) < 1
            selection = [selection i];
        end
    end
% izbira raznih komponent Yn = Winv(:, subset)*icasig(subset, :)
    Winv = inv(W);
    Yapprox = Winv(:, selection) * icasig(selection, :);
    difference = sum(sum(abs(sig) - abs(Yapprox)));
    disp("Sum of difference between approximated and original signal is " + difference);

% osnovni/korigirani signali
    floorStart = -1;
    figure;
    for i=1:size(icasig, 1)
        if floor((i-1)/3) ~= floorStart
            cont = input("show the resulting samples? 'no' to exit", 's');
            if cont == "no"
                break
            end
            clf()
            tiledlayout(3,2);
            floorStart = floorStart + 1;
            disp(i + ", processing next 3")
        end
        if cont == "no"
            break
        end
        nexttile;
        hold on;
        plot(tm, sig(i, :), 'DisplayName','original');
        plot(tm, Yapprox(i, :),'DisplayName','approximation');
        lgnd = legend('Location','westoutside', 'FontSize',8);
        set(lgnd,'color','none');
        hold off;
        %legend({'approximation', 'original'})
        title(i)
        nexttile;
        plot(tm, Yapprox(i, :) - sig(i, :))
        title("difference " + i)
    end

    outputArg1 = Yapprox;
end