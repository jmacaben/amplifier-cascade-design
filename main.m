clear; 
clc;

Vs = 0.05;              % Source voltage (V)
Rs = 100e3;             % Source resistance (ohms)

RL = 250;               % Load resistance (ohms)

P_required = 300e-3;    % Target load power (W)

Vmin = 10e-3;           % Minimum allowable signal (V)

max_stages = 3;         % Maximum number of amplifier stages allowed

% RX optional parallel resistor in first amplifier stage
RX_values = logspace(1, 8, 200);   % Sweep from 10 ohm → 100 Mohm

% Amplifier options
amps(1).name = 'A';
amps(1).Ri = 10e3;
amps(1).Ro = 1e3;
amps(1).Av = 100;

amps(2).name = 'B';
amps(2).Ri = 10e3;
amps(2).Ro = 0.02e3;
amps(2).Av = 1;

amps(3).name = 'C';
amps(3).Ri = 1000e3;
amps(3).Ro = 10e3;
amps(3).Av = 10;

N = length(amps);

valid_configs = {};

% Loop over number of stages (1, 2, 3)
for n = 1:max_stages
    
    % Generate all possible sequences of length n (AAA, AAB, ..., CCC)
    grids = cell(1,n);
    [grids{:}] = ndgrid(1:N);
    idx = reshape(cat(n+1, grids{:}), [], n);
    
    % Loop through each sequence
    for i = 1:size(idx,1)
        
        sequence = amps(idx(i,:));
        names = {sequence.name};
        seq_name = strjoin(names, '');
        
        % Stores best RX option for particular sequence
        best_for_sequence = [];
        
        for RX = RX_values
            
            % Effective input resistnace
            Rin1 = sequence(1).Ri;
            Rin_eff = (Rin1 * RX) / (Rin1 + RX);   % Parallel RX added
            
            V = Vs * (Rin_eff / (Rs + Rin_eff));
            
            min_signal_ok = (V >= Vmin);    % Check minimum voltage constraint         
            
            % Propagate through each stage
            for k = 1:length(sequence)
                
                stage = sequence(k);
                
                % Apply gain
                V = V * stage.Av;
                
                % Determine load
                if k < length(sequence)
                    Rload = sequence(k+1).Ri;   % If it's not the last stage, set to next stage input resistance
                else
                    Rload = RL;
                end
                
                % Output voltage divider
                V = V * (Rload / (stage.Ro + Rload));
                
                % Check minimum voltage constraint
                if V < Vmin
                    min_signal_ok = false;
                end
            end
            
            % Power calculation
            PL = V^2 / RL;
            error = abs(PL - P_required);
            
            % Store best RX for the sequence
            if min_signal_ok
                if isempty(best_for_sequence) || error < best_for_sequence.error
                    best_for_sequence.sequence = seq_name;
                    best_for_sequence.Vout = V;
                    best_for_sequence.PL = PL;
                    best_for_sequence.RX = RX;
                    best_for_sequence.error = error;
                    
                end
            end
            
        end
        
        % Store best version of this sequence
        if ~isempty(best_for_sequence)
            valid_configs{end+1} = best_for_sequence;
        end
    end
end

% Print results
if isempty(valid_configs)
    disp('No valid cascades found.');
else
    
    % Sort by closeness to required power
    errors = cellfun(@(x) x.error, valid_configs);
    [~, order] = sort(errors);
    valid_configs = valid_configs(order);
    
    disp('Top cascade options (closest to required power):');
    
    for i = 1:min(10, length(valid_configs))
        fprintf('%s | RX=%.2e ohm | Vout=%.3f V | PL=%.4f W | error=%.4f\n', ...
            valid_configs{i}.sequence, ...
            valid_configs{i}.RX, ...
            valid_configs{i}.Vout, ...
            valid_configs{i}.PL, ...
            valid_configs{i}.error);
    end
    
    % Best overall
    best = valid_configs{1};
    
    fprintf('\n===== BEST CHOICE =====\n');
    fprintf('Sequence: %s\n', best.sequence);
    fprintf('RX: %.2e ohm\n', best.RX);
    fprintf('Vout: %.3f V\n', best.Vout);
    fprintf('PL: %.4f W\n', best.PL);
end
