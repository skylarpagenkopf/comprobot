function  w(serPort)

    % vars to track
    followingWall = 0;
    returnedToStart = 0;
    leftStart = 0;
    globloc = [0,0,0];
    startloc = [0,0,0];

    % start going forward
    SetFwdVelAngVelCreate(serPort,0.2,0);

    while ~followingWall
        % update x,y position
        distance = DistanceSensorRoomba(serPort);
        angle = AngleSensorRoomba(serPort);
        globloc = updatePosition(globloc, distance, angle);
        % get bump sensors
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

    % loop forever, will break when reach the starting point
    while ~returnedToStart
        pause(0.2);
        % update x,y position
        distance = DistanceSensorRoomba(serPort);
        angle = AngleSensorRoomba(serPort);
        globloc = updatePosition(globloc, distance, angle);
        % get bump sensors
        [ BumpRight, BumpLeft, ~, ~, ~, BumpFront] = BumpsWheelDropsSensorsRoomba(serPort); % Read Bumpers
        wall = WallSensorReadRoomba(serPort);
        if ~leftStart && sqrt( (globloc(1) - startloc(1))^2 + (globloc(2) - startloc(2))^2 ) > .25
            disp('left start');
            leftStart = 1;

        elseif leftStart && sqrt( (globloc(1) - startloc(1))^2 + (globloc(2) - startloc(2))^2 ) <= .25
            disp('returned to start');
            returnedToStart = 1;
            SetFwdVelAngVelCreate(serPort,0,0);
            BeepRoomba(serPort);

        % if we bumped, figure out what to do
        elseif BumpFront || BumpRight || BumpLeft
            disp('bump');
            while BumpFront || BumpRight || BumpLeft
                turnAngle(serPort,0.2,1);
                [ BumpRight, BumpLeft, ~, ~, ~, BumpFront] = BumpsWheelDropsSensorsRoomba(serPort); % Read Bumpers
            end      
        % following the wall
        elseif wall
            disp('following wall');
            SetFwdVelAngVelCreate(serPort,0.2,0);
        % lost the wall
        elseif ~wall
            disp('lost wall');
            SetFwdVelAngVelCreate(serPort,0.2,-1);
            while ~wall && ~BumpFront && ~BumpRight && ~BumpLeft
                wall = WallSensorReadRoomba(serPort);
                [ BumpRight, BumpLeft, ~, ~, ~, BumpFront] = BumpsWheelDropsSensorsRoomba(serPort);
            end
        end
    end  
end

function [globloc] = updatePosition(globloc, distance, angle)
    globloc(1) = globloc(1) + (distance * cos(globloc(3)));
    globloc(2) = globloc(2) + (distance * sin(globloc(3)));
    globloc(3) = globloc(3) + angle;
    globloc(3) = mod(globloc(3), 2.0*pi);
end

function [followingWall, globloc] = senseBumperContact(serPort, followingWall, globloc)
    [ BumpRight, BumpLeft, ~, ~, ~, BumpFront] = BumpsWheelDropsSensorsRoomba(serPort); % Read Bumpers
    if BumpRight || BumpLeft || BumpFront
       SetFwdVelAngVelCreate(serPort,0,0);
    end
end
