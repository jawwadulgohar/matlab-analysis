function mc_struct_viewer(struct, options)
% This launches a struct viewer that allows simple navigation and viewing
% of MC structs.
%
% Inputs:
% struct:	The mc_struct, as returned by mc_read_data. If this foregone
%				you will be prompted to load one from file. Pass a non-struct
%				if you want the default.
% options:	Options for automated viewing, must be a struct generated by
%				mc_options. Default is mc_options();
%
% Usage:
% mc_struct_viewer([struct, options]);

% Parse the defaults.
if(~exist('struct', 'var') || ~isstruct(struct))
    struct = mc_read_data;
end
s = struct;

if(~exist('options', 'var') || ~isstruct(options))
    options = mc_options;
end
o = options;

% Either make a new figure or set the current figure to be whatever the
% last one was, depending on options.
fig = findobj('type', 'figure', 'name', o.name);
if(isempty(fig) || o.newfig)
    fig = figure('name', o.name);
elseif(length(fig) > 1)
    fig = fig(1);
end
figure(fig);

% Clear and build the figure.
%us = build_ui(s, fig);

% Check to see if we can plot the curves if necessary.
if(o.mpulse && o.c ~= 0)
    o.c = 0;
end

if(o.c > 1 && (~isfield(s, 'win') || (o.c == 1 && (~isfield(s.win, 'c') ||...
        ~isfield(s.win, 'ct'))) || (o.c == 2 && (~isfield(s.win, 'p') ||...
        ~isfield(s.win, 'it')))))
    o.c = 0;
end

if(o.mpulse || o.c == 2 || o.c == 1)
    ch = ishold;
    
    if(~ch)
        cla;
    end
    
    hold all;
    % Reconstitute the fullness of the thing, such that for each point in
    % the indirect dimension step there is a cell for 'c' constituting
    % windows + transients.
    cind = num2cell(s.win.ind);
    
    if(o.c == 1 || o.mpulse)
        time = s.win.ct;
        val = s.win.ac;
    else
        time = s.win.it;
        val = s.win.ap;
    end
    
    if(o.mpulse)
        % Find the dimension along which it varies.
        vardim = find(s.prog.vtypes == 2, 1, 'first');
        dswap = 1:length(s.win.ind);
        dswap([1, vardim]) = [vardim, 1];
        
        us.mplots = zeros(s.win.ind);
        
        scrsz = get(0, 'ScreenSize');
        figsz = [scrsz(3)*0.125, scrsz(4)*0.125, scrsz(3)*0.6, scrsz(4)*0.6];
        set(fig, 'Position', figsz, 'NumberTitle', 'off');

        us.axes = gca;
        set(us.axes, 'Position', [0.0625, 0.15, 0.9, 0.8]);
        us.title = title(s.Filename(1:(end-4)), 'FontWeight', 'demi');
        set(us.axes, 'Title', us.title);
        
        tstr = '';
        
        for i = 1:length(time(:))
            [cind{:}] = ind2sub(s.win.ind(dswap), i);
            cind = cind(dswap); % Swap back.
            
            ltypes = {'-', '--', '-*', '-+', '-x', ':'};
            lcols = {'k', 'r', 'b', 'g', 'm'};
            lab = num2str(cind{1}-1);
            
            if(cind{vardim} == 1 && vardim ~= 1)
                tstr = [tstr, num2str(cind{1}-1)];
            end
            
            for j = 2:length(cind)
                lab = [lab, ', ',  num2str(cind{j}-1)]; %#ok
            
                if(cind{vardim} == 1 && j ~= vardim)
                   tstr = [tstr, ', ', num2str(cind{j}-1)]; 
                end
            end
            
            if(cind{vardim} == 1)
                tstr = [tstr, '|'];
            end
            
            plot_cells = {time{cind{:}}, val{cind{:}}};
            
            vis = 'on';
            if(i > s.prog.maxsteps(vardim))
                vis = 'off';
            end
            
            us.mplots(cind{:}) = plot(us.axes, plot_cells{:}, ...
                [ltypes{mod(cind{vardim}-1, length(ltypes))+1}, ...
                lcols{mod(cind{vardim}-1, length(lcols))+1}], ...
                'DisplayName', lab, 'Visible', vis); 
        end
%         % Calculate the length of the longest index.
%         i2 = s.win.ind(dswap);
%         l = prod(i2(2:end));
%         if(l > 0)
%             num = floor(log10(l))+1;
%         else
%             num = 1;
%         end
        
%         tstr = char(zeros(1, (num+1)*l));
%         fstr = sprintf('%%0%dd|', num);
%         
%         for i = 0:(l-1)
%            tstr(((i)*(num+1)+1):((i+1)*(num+1))) = sprintf(fstr, i); 
%         end

        tstr(end) = [];
        
        op = findobj('type', 'uicontrol', 'Tag', 'ChangePulldown');
        if(~isempty(op))
           delete(op); 
        end
        
        tpullpos = [0.87, 0.025, 0.1, 0.05];
        tpullpos(1:2:end) = tpullpos(1:2:end)*figsz(3);
        tpullpos(2:2:end) = tpullpos(2:2:end)*figsz(4);
        
        us.mplots = permute(us.mplots, dswap);
        rs = size(us.mplots);
        rs = [rs(1), prod(rs(2:end))];
        us.mplots = reshape(us.mplots, rs);
        
        us.tpull = uicontrol('Callback', {@change_mpulse, us, vardim}, ...
            'Tag', 'ChangePulldown', 'Style', 'popup', 'String', tstr, ...
            'Position', tpullpos);
        
        set(us.tpull, 'UserData', 1);
    else
        for i = 1:length(time(:))
            % The flipping thing is for this specific application, remove it
            % later
            [cind{:}] = ind2sub(fliplr(s.win.ind), i);
            cind = fliplr(cind);
            
            plot_cells = {time{cind{:}}, val{cind{:}}};
            
            ltypes = {'-k', '--r', '-*b'};
            lab = [num2str(cind{1}-1), ', ', num2str(cind{2}-1)];
            
            vis = 'on';
            if(cind{1} > 1)
                vis = 'off';
            end
            
            plot(plot_cells{:}, ltypes{mod(i-1, 3)+1}, 'DisplayName', lab, 'Visible', vis);
        end
    end
    
    if(~ch)
        hold off;
    end
end

figure(fig);

function change_mpulse(obj, event, us, vardim)
ov = get(obj, 'UserData');
nv = get(obj, 'Value');

if(ov == nv)
   return; % No change
end

% Turn off the old stuff
set(us.mplots(:, ov), 'Visible', 'off');
set(us.mplots(:, nv), 'Visible', 'on');

set(obj, 'UserData', nv);




function ui_struct = build_ui(s, fig)
% Builds the axes and the UI struct telling you which ones are which.
set(0, 'CurrentFigure', fig);
clf;

us = struct('fig', fig, ...	% The figure itself
    'axes', [], ...				% The plot axes
    'title', [], ...				% Plot title
    'trans', [], ...				% Transient panel
    'dims', [], ...				% Dimension panel
    'dpull', [], ...				% Dimension pulldown
    'close', [], ...				% Close control
    'legend', [], ...				% The legend
    'legon', [], ...				% Whether or not the legend is on
    'nup', [], ...					% The number to plot at once
    'cax', [], ...					% Current axis
    'new', [], ...					% New dataset
    'recent', [] ...				% Recent data pulldown.
    );

scrsz = get(0, 'ScreenSize');
figsz = [scrsz(3)*0.125, scrsz(4)*0.125, scrsz(3)*0.6, scrsz(4)*0.6];
set(fig, 'Position', figsz, 'NumberTitle', 'off');

us.axes = axes;
set(us.axes, 'Position', [3/64, 5/32, 0.75, 0.8]);
us.title = title(s.Filename(1:(end-4)), 'FontWeight', 'demi');
set(us.axes, 'Title', us.title);

% Transient pulldown
if(s.prog.nt > 1)
    tstr = 'Average|'
else
    tstr = '';
end

for i = 1:s.prog.nt
    tstr = [tstr, num2str(i), '|'];
end
tstr(end) = [];

tpullpos = [0.85, 0.9, 0.1, 0.05];
tpullpos(1:2:end) = tpullpos(1:2:end)*figsz(3);
tpullpos(2:2:end) = tpullpos(2:2:end)*figsz(4);

us.tpull = uicontrol('Style', 'popup', 'String', tstr, 'Position', tpullpos);

% Dimension pulldowns

ui_struct = us;

function plot_data(c, fft, steps, color)
% This is the function which actually plots the data from the steps.
if(c)
    
end




