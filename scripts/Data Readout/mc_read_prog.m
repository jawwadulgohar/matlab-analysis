function prog = mc_read_prog(path)
% Either pass this a path to load or pass it an mc_read_bin struct and it
% will parse out a program from it.
%
% Usage:
% prog = mc_read_prog;
% prog = mc_read_prog(path);
% prog = mc_read_prog(struct);

if(~exist('path', 'var'))
	path = -1;
end

if(~isstruct(path))
	s = mc_read_bin(path, 'mc_read_pp_hist.mat');
else
	s = path;
end

% Field names and such
MCD_PROGHEADER = 'PulseProgram';

MCD_NDPC = 'NDPC';
MCD_ANALOGOUT = 'AnalogOutput';
MCD_PULSEPROPS= 'Properties';
MCD_INSTRUCTIONS = 'Instructions';

MCD_STEPS = 'steps';
MCD_MAXSTEPS = 'maxsteps';
MCD_DATAEXPRS = 'dataexprs';
MCD_DELAYEXPRS = 'delayexprs';
MCD_VINS = 'v_ins';
MCD_VINSDIM = 'v_ins_dim';
MCD_VINSMODE = 'v_ins_mode';
MCD_VINSLOCS = 'v_ins_locs';

MCD_AOVARIED = 'ao_varied';
MCD_AODIM = 'ao_dim';
MCD_AOVALS = 'ao_vals';

prog = [];
p = find_struct_by_field(s, MCD_PROGHEADER);
if(~isempty(s))
	prog = p.(MCD_PULSEPROPS);
	
	if(isfield(p, MCD_NDPC))
		s1 = p.(MCD_NDPC);
		if(isfield(s1, MCD_MAXSTEPS))
			prog.maxsteps = s1.(MCD_MAXSTEPS);
		end
		
		if(isfield(s1, MCD_STEPS))
			prog.steps = s1.(MCD_STEPS);
		end
		
		if(isfield(s1, MCD_VINS))
			prog.vins = s1.(MCD_VINS);
		end
		
		if(isfield(s1, MCD_VINSDIM))
			prog.vinsdim = s1.(MCD_VINSDIM);
		end
		
		if(isfield(s1, MCD_VINSMODE))
			prog.vinsmode = s1.(MCD_VINSMODE);
		end
		
		if(isfield(s1, MCD_VINSLOCS))
			prog.vinslocs = s1.(MCD_VINSLOCS);
		end
		
		if(isfield(s1, MCD_DELAYEXPRS))
			prog.delayexprs = s1.(MCD_DELAYEXPRS);
		end
		
		if(isfield(s1, MCD_DATAEXPRS))
			prog.dataexprs = s1.(MCD_DATAEXPRS);
		end
		
		
	end
	
	if(isfield(p, MCD_ANALOGOUT))
		s1 = p.(MCD_ANALOGOUT);
		if(isfield(s1, MCD_AOVALS))
			prog.aovals = s1.(MCD_AOVALS);
		end
		
		if(isfield(s1, MCD_AOVARIED))
			prog.aovaried = s1.(MCD_AOVARIED);
			
			if(any(prog.aovaried) && isfield(s1, MCD_AODIM))
				prog.aodim = s1.(MCD_AODIM);
				
				prog.aodim(prog.aodim > 8) = -1;
				prog.aodim = prog.aodim+1;
			end
		end
	end
	
	if(isfield(p, MCD_INSTRUCTIONS))
		s1 = uint8((p.(MCD_INSTRUCTIONS))');
		nfields = typecast(s1(1:4), 'int32');
		prog.instrs = cell(prog.nUniqueInstrs+1, nfields);
		sizes = zeros(nfields, 1);
		types = cell(nfields, 1);
		
		j=5;
		for i = 1:nfields
			l = typecast(s1(j:j+3), 'int32'); % Get the length of the field name
			if(l > 10000)
				error('Memory overload.');
			end
			
			j = j+4;
			
			% Flags
			prog.instrs{1, i} = deblank(char(s1(j:j+l-2)));
			j = j+l;
			
			if(strncmp(prog.instrs{1, i}, 'instr_data', length('instr_data')))
				prog.instrs{1, i} = 'data';
			end
			
			if(strncmp(prog.instrs{1, i}, 'trigger_scan', length('trigger_scan')))
				prog.instrs{1, i} = 'scan';
			end
			
			if(strncmp(prog.instrs{1, i}, 'instr_time', length('instr_time')))
				prog.instrs{1, i} = 'time';
			end
			
			if(strncmp(prog.instrs{1, i}, 'time_units', length('time_units')))
				prog.instrs{1, i} = 'units';
			end
			
			type = typecast(s1(j), 'uint8');
			sizes(i) = fs_size(type);
			types{i} = fs_type(type);
			
			j = j+1;
		end
		
		
		units = {'ns', 'us', 'ms', 's'};
		for i=1:prog.nUniqueInstrs
			for k=1:nfields
				prog.instrs{i+1, k} = typecast(s1(j:(j+sizes(k)-1)), types{k});
					
				j = j+sizes(k);
			end
			
			prog.instrs{i+1, 5} = prog.instrs{i+1, 5}*10^(-double(prog.instrs{i+1, 6})*3);
			prog.instrs{i+1, 6} = units{prog.instrs{i+1, 6}+1};
		end
	end
else
	return;
end

if(isfield(prog, 'instrs'))
	prog.ps = parse_instructions(prog);
    p = prog;
    
    % If it's varied in indirect dimensions, read out the values.
    
	 if(prog.nDims)
		  vtype = zeros(prog.nDims, 1);
        
		  if(isfield(prog, 'vinsdim'))
			  ps = prog.ps;

			  % Cell array along each dimension for each thing, also creates a
			  % bool array determining if each dimension varies delay, data or
			  % both.

			  dels = {};
			  datas = {};

			  for d = 1:p.nDims
					ins = p.vins(p.vinsdim == d);
					vdata = zeros(p.maxsteps(d), length(ins));
					vdel = vdata;

					cind = num2cell(ones(size(size(ps.vinstrs))));

					for i = 1:p.maxsteps(d)
						 cind{d} = i;

						 for j = 1:length(ins)
							  k = ins(j);  
							  vdata(i, j) = ps.vinstrs(cind{:}).data(k+1);
							  vdel(i, j) = ps.vinstrs(cind{:}).ts(k+1);
						 end
					end

					dels = [dels, {vdel}];
					datas = [datas, {vdata}];

					for i = 1:length(ins)
						 if(~isempty(find(vdel(1, i) ~= vdel(:, i), 1, 'first')))
							  vtype(d) = bitor(vtype(d), 1);
						 end

						 if(~isempty(find(vdata(1, i) ~= vdata(:, i), 1, 'first')))
							  vtype(d) = bitor(vtype(d), 2);
						 end
					end
			  end
			  
			  prog.vdel = dels;
			  prog.vdata = datas;
		  end
        
        prog.vtypes = vtype;
    end
end