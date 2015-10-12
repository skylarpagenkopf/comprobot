function  w(serPort)

% vars to track
followingWall = 0;
returnedToStart = 0;
leftStart = 0;
globloc = [0,0,0];
startloc = [0,0,0];
goalloc = [2,3,0];
slope = [0,0];

while sqrt( (globloc(1) - goalloc(1))^2 + (globloc(2) - goalloc(2))^2 ) >= .3
    % update x,y position
    globloc = updatePosition(serPort, globloc);
    slope = findMLine(goalloc, startloc);
    if intersectM(slope, globloc)
        disp('found M!');
        followM(serPort, globloc, goalloc);
    else
    % get bump sensors//follow wall until reaquire Mline
    [ BumpRight, BumpLeft, ~, ~, ~, BumpFront] = BumpsWheelDropsSensorsRoomba(serPort); % Read Bumpers
    if BumpRight || BumpLeft || BumpFront
       SetFwdVelAngVelCreate(serPort,0,0);
       % if the first bump, update start loc
       disp('init bump');
       followingWall = 1;
       startloc(1) = globloc(1);
       startloc(2) = globloc(2);
       startloc(3) = globloc(3);
       disp(startloc);
    end
    pause(0.2);
    end
end

% loop forever, will break when reach the starting point
while ~returnedToStart
    if ~leftStart && sqrt( (globloc(1) - startloc(1))^2 + (globloc(2) - startloc(2))^2 ) > .3
        disp('left start');
        leftStart = 1;
    end
    if leftStart && sqrt( (globloc(1) - startloc(1))^2 + (globloc(2) - startloc(2))^2 ) <= .3
        disp('returned to start');
        returnedToStart = 1;
        SetFwdVelAngVelCreate(serPort,0,0);
        BeepRoomba(serPort);
    end
    % uncomment this line if you want to see it work inside of an obj
    % SetFwdVelAngVelCreate(serPort,0.15,-1);
end
    
end

function [globloc] = updatePosition(serPort, globloc)
    distance = DistanceSensorRoomba(serPort);
    angle = AngleSensorRoomba(serPort);
    globloc(1) = globloc(1) + (distance * cos(globloc(3)));
    globloc(2) = globloc(2) + (distance * sin(globloc(3)));
    globloc(3) = globloc(3) + angle;
    globloc(3) = mod(globloc(3), 2.0*pi);
end

function [slope] = findMLine(goalloc, startloc) 
    x = goalloc(1) - startloc(1);
    y = goalloc(2) - startloc(2);
    signY = sign(y);
    if x == 0 && y ~= 0
        slope = [inf, signY];
    else
        slope = [y/x, signY];
    end
end

function [onM] = intersectM(slope, globloc)
    if globloc(2) == slope * globloc(1)
        onM = 1; 
    else
        onM = 0;
    end
end

function [] = followM(serPort, globloc, goalloc)
    rot = atand((goalloc(2) - globloc(2))/(goalloc(1) - globloc(1)));
    globloc = updatePosition(serPort, globloc);
    turn = rot - (globloc(3) * 57.2958);
    if turn > 0
        turnAngle(serPort,.2,turn);
    end
    
    SetFwdVelAngVelCreate(serPort,0.15,0);
end