function stInfo=parseCVML(infile)
% read bounding boxes in CVML format
% 
% (C) Anton Milan, 2012-2013

% first determine the type
[~, ~, fileext]=fileparts(infile);

% for now, we can only read CVML schema
if  strcmpi(fileext,'.xml');
else    error('Unknown type of detections file.');
end

%% now parse
xDoc=xmlread(infile);

allFrames=xDoc.getElementsByTagName('frame');
F=allFrames.getLength;
frameNums=zeros(1,F);
stInfo.X=zeros(F,0);stInfo.Y=zeros(F,0);stInfo.W=zeros(F,0);stInfo.H=zeros(F,0);

%%
for t=1:F
    if ~mod(t,10), fprintf('.'); end
    % what is the frame
    frame=str2double(allFrames.item(t-1).getAttribute('number'));
    frameNums(t)=frame;
    
    objects=allFrames.item(t-1).getElementsByTagName('object');
    Nt=objects.getLength;
%     nObj=size(stInfo.X,2);
    stInfo.X(t,:)=zeros(1,size(stInfo.X,2));stInfo.Y(t,:)=zeros(1,size(stInfo.Y,2));
    stInfo.W(t,:)=zeros(1,size(stInfo.W,2));stInfo.H(t,:)=zeros(1,size(stInfo.H,2));
    for i=0:Nt-1
        id=str2double(objects.item(i).getAttribute('id'));
        if id<1, error('uh oh. IDs should be positive'); end
        box=objects.item(i).getElementsByTagName('box');
        h=str2double(box.item(0).getAttribute('h'));
        w=str2double(box.item(0).getAttribute('w'));
        xc=str2double(box.item(0).getAttribute('xc'));
        yc=str2double(box.item(0).getAttribute('yc'));
        
        % foot position
        stInfo.X(t,id)=xc;       stInfo.Y(t,id)=yc+h/2;
        stInfo.H(t,id)=h;        stInfo.W(t,id)=w;
    end
end
% infile
% stInfo
stInfo.frameNums=frameNums;
% remove zero columns
notEmpty=~~sum(stInfo.X,1);
stInfo.X=stInfo.X(:,notEmpty);
stInfo.Y=stInfo.Y(:,notEmpty);
stInfo.W=stInfo.W(:,notEmpty);
stInfo.H=stInfo.H(:,notEmpty);


% fprintf('all read\n');


end