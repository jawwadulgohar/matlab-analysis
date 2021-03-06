function out = itcmp(y,M,cut) 
% Backward prediction using ITMPM
% ITMPM information theoretic criteria and matrix pencil method 
% function [para,M,itc]=itcmp(y,M)
% author: Yung-Ya Lin, 4/15/96, Updated Paul Ganssle, 6/1/11
% arguments:
% y: complex vector, NMR FID time series
% M: real scalar, number of signals or effective matrix rank
% M=-1 using AIC; M=-2 using MDL; M >= 0 using the user's input value
% para: real M*4 matrix, estimated damping factor, frequency, amplitude, phase
% itc: real vector, containing AIC or MDL function values 
% cut: number of points to cut
%
% Usage:
% out = itcmp(y, M, cut);

ScalingFactor = max(real(y)); 			%to prevent errors due to huge spectral intensities

y=y(:) / ScalingFactor;
N=length(y); 
L=floor(N/3);					% pencil parameter 
Y=toeplitz(y(L+1:N),y(L+1:-1:1));		% Y0=Y(:,2:L+1), Y1=Y(:,1:L) Eq. [3] 

[U,S,V]=svd(Y(:,2:L+1),0);			% singular value decomposition 

S=diag(S);
itc=zeros(1,L); 
if M==-1					% determining M by AIC 
    for k=0:L-1; 
        itc(k+1)=-2*N*sum(log(S(k+1:L))) ... 
            + 2*N*(L-k)*log((sum(S(k+1:L))/(L-k))) + 2*k*(2*L-k); 
    end 
    [tempY, tempI]=min(itc); 
    M=tempI-1; 
end
if M==-2					% determining M by MDL Eq. [16] 
        for k=0:L-1; 
            itc(k+1)=-N*sum(log(S(k+1:L))) ...
                + N*(L-k)*log((sum(S(k+1:L))/(L-k))) + k*(2*L-k)*log(N)/2;
        end
        [tempY, tempI]=min(itc); 
        M=tempI-1;
    end
s=log(eig(diag(1./S(1:M))* ... 			% signal pole z=exp(s) 
  ((U(:,1:M)'*Y(:,1:L))*V(:,1:M)))); 
Z=zeros(N,M); 
for k=1:M
  Z(:,k)=exp(s(k)).^(0:N-1).';
end;

a=Z\y;	% linear least squares analysis 

para=[-real(s) imag(s)/2/pi abs(a) imag(log(a./abs(a)))];


%
%protect routine against NaN phases and/or amplitudes
%
QTEMP5 = [];
QTEMP3 = isnan(para);
for QTEMP4 = 1:size(para, 1)
  if isempty(find(QTEMP3(QTEMP4, :),1))
    QTEMP5 = [QTEMP5; QTEMP4];
  end
end
if (length(QTEMP3) < size(para, 1))
  disp('ITCMP NOTICE: protecting LP fit against NaN')
  para = para(QTEMP5, :);
end


%
%protect routine against very small amplitudes. Everything smaller than 10^-4 of the sum amplitude is deleted
%
QTEMP3 = find( (para(:, 3) > sum(abs(para(:, 3)))/1e6) & (para(:, 3) > 1e-6) );
if (length(QTEMP3) < size(para, 1))
  disp('ITCMP NOTICE: protecting LP fit against small amplitudes')
  para = para(QTEMP3, :);
end


%
%refuse to accept negative dampening factors (explode in time!)
%
QTEMP3 = find( para(:, 1).*abs(sign(para(:, 2))) >= 0 );
if (length(QTEMP3) < size(para, 1))
  disp('ITCMP NOTICE: protecting LP fit against negative dampening factors')
  para = para(QTEMP3, :);
end


%
%rescale the amplitude back
%
para(:, 3) = para(:, 3)*ScalingFactor;


% ==== arguments ====
% lp: complex time series index vector
% para: spectral parameters, M*4
%       para=[damping factor,frequency,amplitude,phase]
% sn: s/n ratio
% varw: noise variance                      
% randseed: seed for randon number generator
% y: the simulated complex FID with noise 1*N complex
% ypure: the simulated complex FID without noise 1*N complex
% w: normal dist. white noise 1*N complex

sn = 30;

lp=(0:cut-1)';
[M,temp]=size(para);
delta=sqrt((sum(para(:,3).^2))/(2*10^(sn/10))); % delta: noise standard deviation
ypure=zeros(size(lp));
ypure=ypure(:);
for ii=1:M
    ss=-para(ii,1)+1i*2*pi*para(ii,2);
    ypure=ypure+(para(ii,3)*exp(ss*lp+1i*para(ii,4))); % FID w/o noise     
end %ii

w=delta*randn(size(ypure))*sqrt(-1); % noise
w=w+delta*randn(size(ypure));
y=ypure+w; % y: FID with noise    
out = y;
%varw=std(w).^2;
