%@function: AF2th for single - lead ECGs with adaptive threshold
%@date: 16.6.2009
%@author Helena Loose 
function [beats2]=sn_QRSAF2(X,factor,fth,part,ok)
%-----------------------------------------------------------------------
%INPUT:
%mitfile:signalfile in physiotoolkit format (mit). 
%        consists of *.hea and *.dat
%factor: amplitude threshold scaling factor
%fth: fixed constant threshold
%part: "window number"
%ok: "eye-closing-period" 
%OUTPUT: 
%beats2: sample numbers of beat locations, detections
% 
% MODIFICATIONS
% 20170301 (DK): Function rename

%-----------------------------------------------------------------------
beats2=[];
beats=[];
n=length(X);
%amplitude threshold, fraction of largest positiv amplitude of signal
%authors choice: 0.4
th=factor*max(X(2:n-1));
count=1;
%raw data is rectified
Y0=abs(X(2:n-1));
%rectified ECG is passed through low level clipper
ind=find(Y0<th);
Y0(ind)=th;
n=length(Y0);
%first derivative for each point of clipped, rectified ECG
Y01=Y0(3:n);
Y02=Y0(1:n-2);
Y2=Y01-Y02;
%QRS candidate:Y2(n) exceeds fixed constant threshold
%authors choice: 0.7
ind=find(Y2>fth);
beats=ind+3;
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