function [rrdata,results,fast,fastN,anno] = sn_CQRS(ecg,sf,varargin)
%reads ecg signal (as double array) and gets QRS-events
%based on cqrs from Helena Loohse
%% Metadata-----------------------------------------------------------
% Dagmar Krefting, 13.5.2015, dagmar.krefting@htw-berlin.de
% Version: 1.0
%-----------------------------------------------------------
%
%USAGE: rrdata = sn_CQRS(ecg,varargin)
%
%INPUT:
%ecg        array of ecg data
%sf         sampling frequency of the ecg data 
%
%OPTIONAL INPUT:
% mintd_rr  minimum time difference between two r wave peaks in seconds, default: 0.160 s
% wls        windowlength of signal feature extraction in seconds, default 4 secs
% FD1_slopeTh slopethreshold for QRS-method FD1th, default 0.2
% AF2_ampFactorTh scaling factor threshold for AF2th-method, default 0.65
% AF2_ampTh fixed threshold for amplitude in AF2th-method, default 0.8
% DF2_ampFactorTh scaling factor threshold for DF2th-method, default 0.125
% DF2_windowSize window size for DF2th-method, default 3
% ch_emgchin channelnumber of chin (submental) EMG signal, default 10;
%
% DEPENDENCIES
% sn_QRSFD1
% sn_QRSAF2
% sn_QRSDF2
%
%-----------------------------------------------------------------------
%MODIFICATION
%20170301 (DK): renaming of qrs functions 

%% Defaults

%minimum time difference between two r wave peaks
mintd_rr = 0.160;

%window length in seconds
wls = 4;

% Input parameter FD1th
FD1_slopeTh = 0.2;

% Input parameter AF2th
AF2_ampFactorTh = 0.65;
AF2_ampTh = 0.8;

% Input parameter DF2th
DF2_ampFactorTh = 0.125;
DF2_windowSize = 3;

%% Check for input vars
%size of varargin
m = size(varargin,2);

%if varargin present, check for keywords and get parameter
if m > 0
    %disp(varargin);
    for i = 1:2:m-1
        %outputfile
        if strcmp(varargin{i},'mintd_rr')
            mintd_rr = varargin{i+1};
            %outputfile
        elseif strcmp(varargin{i},'wls')
            wls = varargin{i+1};
        elseif strcmp(varargin{i},'FD1_slopeTh')
            FD1_slopeTh = varargin{i+1};
        elseif strcmp(varargin{i},'AF2_ampFactorTh')
            AF2_ampFactorTh = varargin{i+1};
        elseif strcmp(varargin{i},'AF2_ampTh')
            AF2_ampTh = varargin{i+1};
        elseif strcmp(varargin{i},'DF2_ampFactorTh')
            DF2_ampFactorTh = varargin{i+1};
        elseif strcmp(varargin{i},'DF2_windowSize')
            DF2_windowSize = varargin{i+1};
        elseif strcmp(varargin{i},'debug')
            debug = varargin{i+1};
        end
    end
end


%% Derived parameters

%signal length
sl = length(ecg);

%minimum sample difference between two RR-peaks
minsd_rr = mintd_rr*sf;

%window length in samples
wl=4*sf;

%Last window sample index
lwindex = sl -mod(sl,wl)-wl;

%no idea, probably I can skip
% last=-minsd_rr

%array for the results: 1: FD1th, 2: AF2th, 3 DF2th
results = false(wl,3);

%counter
cloop = 1;

%% perform QRS detection

for i=1:wl:lwindex
      % disp(['Window index: ', num2str(i)])
      resultFD1 = sn_QRSFD1(ecg(i:i+wl-1),FD1_slopeTh,i,minsd_rr);
      resultAF2 = sn_QRSAF2(ecg(i:i+wl-1),AF2_ampFactorTh,AF2_ampTh,i,minsd_rr);
      resultDF2 = sn_QRSDF2(ecg(i:i+wl-1),DF2_ampFactorTh,i,DF2_windowSize,minsd_rr);
      %set the samples detected by algorithms true
      results(resultFD1,1) = true;
      results(resultAF2,2) = true;
      results(resultDF2,3) = true;
      cloop = cloop + 1;
end

%rrdata = results;
%fclose(fidFD1); 

%get the R-wave events
%FD1
anno = find(results(:,1));
%AF2
anno1 = find(results(:,2));
%DF2
anno2 = find(results(:,3));

%% Check for consistent data and compare data

% Calculate heart rate for first method (FD2)
beats=length(anno);
beat1=anno(1:beats-1);
beat2=anno(2:beats);
b=beat2-beat1;
b=b./sf;
HF=60./(b);

%% use original nomenclatura
%minsd_rr
ok=minsd_rr;
% window length
int = wl;
%% ------------------------------------------------------------------------
%------------------Betrachtung moeglicher Falsch Positiver-----------------
%--------------------------------------------------------------------------
%finde Abschnitte in denen die Herzfrequenz ueber 140bpm steigt
fast=find(HF>140);
% debug
disp([ num2str(length(fast)) ' distances resulting in 140 bpm found'])

%betrachte auch den jeweils naechsten Punkt um zu wissen, welcher der 
%beiden FP sein koennte
fastN=fast+1;
%Anzahl der Punkte mit zu hoher Herzfrequenz
l=length(fast);
%Vektoren zur Speicherung der Kandidaten
trueE=zeros(l,1);
trueEN=zeros(l,1);

%loop over all suspicions R peak events
for i=1:l
    %besorge das Object of Question (ooq)
    ooq=anno(fast(i));
    ooqN=anno(fastN(i));
    
    %suche das ooq in einem der anderen Beatsannotationen
    %AF2
    exist=find(anno1>(ooq-ok) & anno1<(ooq+ok));
    existN=find(anno1>(ooqN-ok) & anno1<(ooqN+ok));
    %DF2
    exist2=find(anno2>(ooq-ok) & anno2<(ooq+ok));
    existN2=find(anno2>(ooqN-ok) & anno2<(ooqN+ok));
    %Wenn ein passender Punkt gefunden wurde, dann ist anzunehmen, dass es
    %sich hier wirklich um einen QRS-Komplex handelt
    if ((length(exist)~=0) | (length(exist2)~=0))
        %merke dir das dieser Punkt relevant ist
        trueE(i)=1;
        %disp('Matching point for event found')
    end

    if ((length(existN)~=0) | (length(existN2)~=0))
        %merke dir das dieser Punkt relevant ist
        trueEN(i)=1;
        %disp('Matching point for second event found')
    end

end
%suche alle Punkte, die aus der Annotation geloescht werden sollen
remove=find(trueE==0);
removeN=find(trueEN==0);

disp([ num2str(length(remove)) 'first events will be removed'])
disp([ num2str(length(removeN)) 'second events will be removed'])


%% ------------------------------------------------------------------------
%------------------Betrachtung moeglicher Falsch Negativer-----------------
%--------------------------------------------------------------------------
%finde Abschnitte, die eine zu kleiner Frequenz aufweisen, wahrscheinlich
%ausgelassene Beats, FN

slow=find(HF<=40);
%schraenke Bereich ein in dem ein Beat fehlen koennte
slowN=slow+1;

%Anzahl der moeglichen FN
sl=length(slow);
extraBeat=[];
mehr=1;
for i=1:sl
    extra=find(anno1>(anno(slow(i))+ok) & anno1<(anno(slowN(i))-ok));
    if ((length(extra)~=0))
        for z=1:length(extra)
            extraBeat(mehr,z)=anno1(extra(z));
        end
        
        mehr=mehr+1;
        
    end
end

%mehrere Beats m�glich
if size(extraBeat,2)>1
    indExtra=find(extraBeat(:,2)-extraBeat(:,1)>ok);
end

med=10000;
%% keine Beats in verrauschten Bereichen setzen
if length(extraBeat)~=0
    for w=1:size(extraBeat,1)
       oho=mod(extraBeat(w,1),int);
       start=extraBeat(w,1)-oho;
    if(start<=0)
       start=1;
    end    
       gross=max(ecg(start:start+int-1));
    
        if (gross>med*1.5)
            extraBeat(w,:)=0;
        end
    end
end
%% Zusammenfassung der als zu aussortieren markierten Punkte
FP1=anno(fast(remove));
FP2=anno(fastN(removeN));

FP=unique([FP1;FP2]);

%annotation ohne die aussortierten FP
aKorr=setdiff(anno,FP);

%% annotation ohne die aussortierten FN
if size(extraBeat,2)>0
    add=find(extraBeat(:,1)>0);
    aKorr1=[aKorr;extraBeat(add,1)];
else
    aKorr1=aKorr;
end
if size(extraBeat,2)>1
    add=find(extraBeat(indExtra,2)>0);
    aKorr2=[aKorr1;extraBeat(add,2)];
else
    aKorr2=aKorr;
end

if size(extraBeat,2)>2
    check=find(extraBeat(:,3)>0);
    add=extraBeat(check,3);
    aKorr3=[aKorr2;add];
else
    aKorr3=aKorr2;
end

aKorr3=sort(aKorr3);
aKorr3=setdiff(aKorr3,0);

rrdata = aKorr3; 

% %% Die gefundene Annotation wird in eine Datei geschrieben
% outfile=[mitfile,'_cqrs.dat'];
% infoCV=['#Verfahren: CQRS mit Fenstergroesse: ',num2str(int)];
% fidCV=fopen(outfile,'w');
% fprintf(fidCV,'%s\n',Hline);
% fprintf(fidCV,'%s\n',Hline2);
% fprintf(fidCV,'%s\n',infoCV);
% fprintf(fidCV,'%d\n',aKorr3);
% fclose(fidCV);