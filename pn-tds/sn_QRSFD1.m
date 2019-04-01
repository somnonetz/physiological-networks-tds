%@function: Function FD1 for single - lead ECGs with adaptive threshold
%@date: 16.6.2009
%@author: Helena Loose 
function [beats2]=sn_QRSFD1(X,sth,part,ok)
%-----------------------------------------------------------------------
%INPUT:
%mitfile:signalfile in physiotoolkit format (mit). 
%        consists of *.hea and *.dat
%sth: slope threshold
%part: "window number"
%ok: "eye-closing-period" 
%OUTPUT: 
%beats2: sample numbers of beat locations, detections
% 
% MODIFICATIONS
% 20170301 (DK): Function rename

%-----------------------------------------------------------------------
%signal length
n=length(X);
%-----------------------------------------------------------------------
%first derivative using Menard formula
X1=X(2:n-5);
X2=X(3:n-4);
X3=X(5:n-2);
X4=X(6:n-1);
Y=-2*X1-X2+X3+2*X4;
%slope threshold, fraction of max. slope of derivative ECG
%authors choice: 0.7
th=sth*max(Y);
%search derivatives that exceed slope threshold
ind=find(Y>th);
%account for index shift in derivative, get index for signal (+2)
beats=ind+2;
% some counter
c=2;

% define beats2 as empty variable
beats2 = [];

%proceed if values above threshold are found
if length(beats)~=0
    % disp('beats not empty')
    for z=2:length(beats)
        beats2(1)=beats(1);
        if (beats(z)-beats(z-1))>ok
            beats2(c)=beats(z);
            c=c+1;
        end
    end
    beats2=beats2+part;
end
