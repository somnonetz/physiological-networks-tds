%@function: DF2 for single - lead ECGs
%@date: 16.6.2009
%@author: Helena Loose 
function [beats2]=sn_QRSDF2(X,factor,part,m,ok)
%-----------------------------------------------------------------------
%INPUT:
%mitfile:signalfile in physiotoolkit format (mit). 
%        consists of *.hea and *.dat
%factor: threshold scaling factor
%m: window size, default 3
%part: "window number"
%ok: "eye-closing-period" 
%OUTPUT: 
%beats2: sample numbers of beat locations, detections
% 
% MODIFICATIONS
% 20170301 (DK): Function rename

%-----------------------------------------------------------------------
n=length(X);
beats2=[];
beats=[];
%smoothes ECG using three-point moving average filter
X1=X(2:n-4);
X2=X(4:n-2);
Y0=X1+2*X(3:n-3)+X2/4;
%digital low pass filter
windowSize = 2*m+1;
Y0sum=filter(ones(1,windowSize),1,Y0);
Y1=(1/(2*m+1)).*Y0sum;
%difference between input and output of lowpass is squared
Y2=(Y0(1:length(Y0))-Y1).^2;
%squared difference is filtered
Y2sum=filter(ones(1,windowSize),1,Y2(windowSize:length(Y2)));
Y3=Y2(windowSize:length(Y2)).*(Y2sum.^2);
Ya=Y0(1:length(Y3)-m);
Yb=Y0(1+m:length(Y3));
Yc=Y0(1+2*m:length(Y3)+m);
Z1=Ya-Yb;
Z2=Yb-Yc;
Z=Z1.*Z2;
ind=find(Z<=0);
Y4=Y3;
Y4(ind)=0;
%max., scaled value of y4 is threshold
%authors choice: 0.125
th=factor*max(Y4);
%QRS candidate: Y4 exceeds threshold
beats=find(Y4>th);
beats=beats+4;
c=2;
if length(beats)~=0
    for z=2:length(beats)
        beats2(1)=beats(1);
        if (beats(z)-beats(z-1))>ok
            beats2(c)=beats(z);
            c=c+1;
        end
    end
end
beats2=beats2+part;