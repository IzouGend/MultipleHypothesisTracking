%[ANR,SNR,STR]	=  ASORT(INP,'OPT',...);
% S		=  ASORT(INP,'OPT',...);
%		   to sort alphanumeric strings numerically if
%		   they contain one properly formatted number
%		   otherwise, ascii dictionary sorting is applied
%
% INP	unsorted input:
%	- a char array
%	- a cell array of strings
% OPT	options
%  -s	- sorting option
%	  '-s','ascend'					[def]
%	  '-s','descend'
%  -st	- force output form S				[def: nargout dependent]
%  -t	- replace matching template(s) with one space
%	  prior to sorting
%	  '-t','template'
%	  '-t',{'template1','template2',...}
%  -w	- remove space(s) prior to sorting
%
%	  NOTE	-t/-w options are processed in the
%		      order that they appear in
%		      the command line
%
%  -v	- verbose output				[def: quiet]
%  -d	- debug mode
%	  save additional output in S
%	  .c:	lex parser input
%	  .t:	lex parser table
%	  .n:	lex parser output
%	  .d:	numbers read from .n
%
% ANR	numerically sorted alphanumeric strings		[eg, 'f.-1.5e+2x.x']
%	- contain one number that can be read by
%	  <strread> | <sscanf>
% SNR	ascii dict  sorted alphanumeric strings
% http://www.mathworks.com/matlabcentral/fileexchange/loadFile.do?objectId=7212#
%
%	- contain more than one number			[eg, 'f.-1.5e +2.x']
%	- contain incomplete|ambiguous numbers		[eg, 'f.-1.5e+2.x']
% STR	ascii dict  sorted strings
%	- contain no numbers				[eg, 'a test']
%
% S	structure with fields
%	.anr
%	.srn
%	.str

% created:
%	us	03-Mar-2002
% modified:
%	us	30-Mar-2005 11:57:07 	/ TMW R14.sp2

%--------------------------------------------------------------------------------
function	varargout=asort(inp,varargin)

varargout(1:nargout)={[]};
if	~nargin
	help(mfilename);
	return;
end

% - common parameters/options
n=[];
ds=[];
anr={};
snr={};
str={};
smod='ascend';	% sorting option
tmpl={};	% template(s)
sflg=false;	% output  mode: structure
tflg=false;	% remove  template(s)
dflg=false;	% debug   mode
vflg=false;	% verbose output
wflg=false;	% remove  spaces

if	nargin > 1
	ix=find(strcmp('-s',varargin));
	if	~isempty(ix) && nargin > ix(end)+1
		smod=varargin{ix(end)+1};
	end
	ix=find(strcmp('-t',varargin));
	if	~isempty(ix) && nargin > ix(end)+1
		tflg=ix(end);
		tmpl=varargin{ix(end)+1};
	end
	if	find(strcmp('-d',varargin));
		dflg=true;
	end
	if	find(strcmp('-st',varargin));
		sflg=true;
	end
	if	find(strcmp('-v',varargin));
		vflg=true;
	end
	ix=find(strcmp('-w',varargin));
	if	~isempty(ix)
		wflg=ix(end);
	end
end
%   spec numbers
ntmpl={
	' inf '
	'+inf '
	'-inf '
	' nan '
	'+nan '
	'-nan '
	};
%   spec chars
ctmpl={
	'.'	% decimal point
	'd'	% exponent
	'e'	% exponent
	};

if	nargout <= 3
	varargout{1}=inp;
else
	disp(sprintf('ASORT> too many output args [%-1d/%-1d]\n',nargout,3));
	help(mfilename);
	return;
end
if	isempty(inp)
	disp(sprintf('ASORT> input is empty'));
	return;
end

ti=clock;
winp=whos('inp');
switch	winp.class
	case	'cell'
		if	~iscellstr(inp)
			disp(sprintf('ASORT> cell is not an array of strings'));
			return;
		end
		inp=inp(:);
		[ins,inx]=sort(inp);
	case	'char'
		%		[ins,inx]=sortrows(inp);
		inp=cstr(inp);
	otherwise
		disp(sprintf('ASORT> does not sort input of class <%s>',winp.class));
		return;
end

inp=inp(:);
inp=setinp(inp,tmpl,[tflg wflg]);
[ins,inx]=sort(inp);
if	strcmp(smod,'descend')
	ins=ins(end:-1:1,:);
	inx=inx(end:-1:1);
end
ins=inp(inx);
c=lower(char(ins));
wins=whos('c');
[cr,cc]=size(c);

% - LEXICAL PARSER
%--------------------------------------------------------------------------------
% - extend input on either side for search
c=[' '*ones(cr,2) c ' '*ones(cr,2)];

% - search for valid alphanumeric items in strings
%   numbers/signs
t=(c>='0'&c<='9');
t=t|c=='-';
t=t|c=='+';
[tr,tc]=size(t);
%   decimal points
%   note: valid numbers with dec points must follow these templates
%         nr.nr
%	  sign.nr
%         nr.<SPACE>
%         <SPACE>.nr
ix1=	 t(:,1:end-2) & ...
	~isletter(c(:,1:end-2)) & ...
	c(:,2:end-1)=='.';
t(:,2:end-1)=t(:,2:end-1)|ix1;
ix1=	(t(:,3:end) & ...
	(~isletter(c(:,3:end)) & ...
	~isletter(c(:,1:end-2))) | ...
	(c(:,3:end)=='e' | ...
	c(:,3:end)=='d')) & ...
	c(:,2:end-1)=='.';
t(:,2:end-1)=t(:,2:end-1)|ix1;
%		t(:,3:end)=t(:,3:end)|ix1;
%   signs
t(c=='-')=false;
t(c=='+')=false;
ix1=	 t(:,3:end) & ...
	(c(:,2:end-1)=='-' | ...
	c(:,2:end-1)=='+');
t(:,2:end-1)=t(:,2:end-1)|ix1;
%   exponents
ix1=	 t(:,1:end-2) & ...
	(c(:,2:end-1)=='e' | ...
	c(:,2:end-1)=='d');
t(:,2:end-1)=t(:,2:end-1)|ix1;
%   spec numbers
c=reshape(c.',1,[]);
t=t';
ic=[];
for	j=1:numel(ntmpl)
	ic=[ic,strfind(c,ntmpl{j})];
end
ic=sort(ic);
for	i=1:numel(ic)
	ix=ic(i)+0:ic(i)+4;
	t(ix)=true;
end
t=t';
c=reshape(c.',[tc,tr]).';
t(c==' ')=false;
%--------------------------------------------------------------------------------

% - only allow one number per string
il=~any(t,2);
ib=strfind(reshape(t.',1,[]),[0 1]);
if	~isempty(ib)
	ixe=cell(3,1);
	n=reshape(char(t.*c).',1,[]);
	for	i=1:numel(ctmpl)
		id=strfind(n,ctmpl{i});
		if	~isempty(id)
			[dum,dum,ixu{i},ixe{i}]=dupinx(id,tc);
		end
	end
	in=false(tr,1);
	im=in;
	%   must check for anomalous cases like <'.d'>
	id=sort(...
		[find(n>='0' & n<='9'),...
		strfind(n,'inf'),...
		strfind(n,'nan')]);
	%		[ibu,ibd,ixbu,ixe{i+1}]=dupinx(id,tc);
	[ibu,ibd,ixbu,ixbd]=dupinx(id,tc);
	in(ixbu)=true;
	in(ixbd)=true;
	[ibu,ibd,ixbu,ixbd]=dupinx(ib,tc);
	im(ixbu)=true;
	in=in&im;
	in([ixe{:}])=false;
	il=~any(t,2);
	ia=~(in|il);

	% - read valid strings
	n=t(in,:).*c(in,:);
	n(n==0)=' ';
	n=char(n);
	dn=strread(n.','%n');
	if	numel(dn) ~= numel(find(in))
		%disp(sprintf('ASORT> unexpected fatal error reading input!'));
		if	nargout
			s.c=c;
			s.t=t;
			s.n=n;
			s.d=dn;
			varargout{1}=s;
		end
		return;
	end

	% - sort numbers
	[ds,dx]=sort(dn,1,smod);
	in=find(in);
	anr=ins(in(dx));
	snr=ins(ia);
end
str=ins(il);
to=clock;

% - prepare output
if	nargout < 3 || sflg
	s.magic='ASORT';
	s.ver='30-Mar-2005 11:57:07';
	s.time=datestr(clock);
	s.runtime=etime(to,ti);
	s.input_class=winp.class;
	s.input_msize=winp.size;
	s.input_bytes=winp.bytes;
	s.strng_class=wins.class;
	s.strng_msize=wins.size;
	s.strng_bytes=wins.bytes;
	s.anr=anr;
	s.snr=snr;
	s.str=str;
	if	dflg
		s.c=c;
		s.t=t;
		s.n=n;
		s.d=ds;
	end
	varargout{1}=s;
else
	s={anr,snr,str};
	for	i=1:nargout
		varargout{i}=s{i};
	end
end

if	vflg
	inp=cstr(inp);
	an=[{'--- NUMERICAL'};		anr];
	as=[{'--- ASCII NUMBERS'};	snr];
	at=[{'--- ASCII STRINGS'};	str];
	nn=[{'--- NUMBERS'};		num2cell(ds)];
	ag={' ';' ';' '};
	u=[{'INPUT'};			inp;ag];
	v=[{'ASCII SORT'};		ins;ag];
	w=[{'NUM SORT'};		an;as;at];
	x=[{'NUM READ'};		nn;as;at];
	w=[u,v,w,x];
	disp(w);
end

return;
%--------------------------------------------------------------------------------
function	c=cstr(s)
% - bottleneck waiting for a good <cellstr> replacement
%   it consumes ~75% of <asort>'s processing time!

c=s;
if	ischar(s)
	sr=size(s,1);
	c=cell(sr,1);
	for	i=1:sr
		c{i}=s(i,:);	% no deblanking!
	end
end
return;
%--------------------------------------------------------------------------------
function	[idu,idd,ixu,ixd]=dupinx(ix,nc)
% - check for more than one entry/row in a matrix of column size <nc>
%   unique    indices:	idu / ixu
%   duplicate indices:	idd / ixd

if	isempty(ix)
	idu=[];
	idd=[];
	ixu=[];
	ixd=[];
	return;
end
id=fix(ix/nc)+1;
idi=diff(id)~=0;
ide=[true idi];
idb=[idi true];
idu=idb & ide;
idd=idb==1 & ide==0;
ixu=id(idu);
ixd=id(idd);
return;
%--------------------------------------------------------------------------------
function	inp=setinp(inp,tmpl,flg)
% - remove space(s) and/or templates

if	isempty(inp) || ~any(flg)
	return;
end

for	i=sort(flg)
	switch	i
		case	flg(1)
			if	ischar(tmpl)
				tmpl={tmpl};
			end
			for	i=1:numel(tmpl)
				inp=strrep(inp,tmpl{i},' ');
			end
		case	flg(2)
			inp=strrep(inp,' ','');
	end
end
return;
%--------------------------------------------------------------------------------
