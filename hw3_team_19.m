% COMS4733 HW3 Team 19
% sap2147 - Skylar Pagenkopf
% rfl2119 - Rich Landy

function hw3_team_19(serPort)
    
    % vars to track
    lastupdate = 0;
    followingObstacle = 0;
    globloc = [0,0,0];
    % track bounds of explored area
    graphXMax = 0;
    graphXMin = 0;
    graphYMax = 0;
    graphYMin = 0;
    % track occupied x y coordinates
    occupiedX = [];
    occupiedY = [];
    
    % start going a random direction

%     % start going forward along line
%     SetFwdVelAngVelCreate(serPort,0.2,0);
    
    while lastupdate < 500
         % update x,y position
         distance = DistanceSensorRoomba(serPort);
         angle = AngleSensorRoomba(serPort);
         globloc = updatePosition(globloc, distance, angle);
         wall = WallSensorReadRoomba(serPort);
         [ BumpRight, BumpLeft, ~, ~, ~, BumpFront] = BumpsWheelDropsSensorsRoomba(serPort); % Read Bumpers
         % update max x, y for graphing later
         if globloc(1) > graphXMax
             graphXMax = globloc(1);
         elseif globloc(1) < graphXMin
             graphXMin = globloc(1);
         end
         if globloc(2) > graphYMax
             graphYMax = globloc(2);
         elseif globloc(2) < graphYMin
             graphYMin = globloc(2);
         end
         % if we bumped into an obstacle, begin following obstacle
         if BumpRight || BumpLeft || BumpFront
             disp('bump');
             occupiedX = [occupiedX, globloc(1)];
             occupiedY = [occupiedY, globloc(2)];
             followingObstacle = 1;
             turnAngle(serPort,0.2,45);
         % if we are following the wall decide whether to leave or keep
         % following
         elseif followingObstacle && wall
             % decide based on lastupdate- if we stopped updating then we
             % have followed the object all the way and can leave in random
             % direction away from the wall
             disp('follow wall or line');
             occupiedX = [occupiedX, globloc(1)];
             occupiedY = [occupiedY, globloc(2)];
             % if we keep following, update grid, reset lastupdate to 0
             SetFwdVelAngVelCreate(serPort,0.2,0);
         elseif ~followingObstacle
             SetFwdVelAngVelCreate(serPort,0.2,0);
         % if we are following the wall and found a corner, turn
         elseif followingObstacle && ~wall
             disp('go around corner');
             SetFwdVelAngVelCreate(serPort,0.2,-1);
         end
         lastupdate = lastupdate + 1;
         pause(0.2);
    end
    
    % plot occupied grid
    diameter = .34;
    graphCellW = floor((graphXMax - graphXMin) / diameter);
    graphCellH = floor((graphYMax - graphYMin) / diameter);
    figure(1);
    axis([min(graphXMin,graphYMin),max(graphXMax,graphYMax),min(graphXMin,graphYMin),max(graphXMax,graphYMax)])
    for i = -graphCellH-1:graphCellH-1
        y = i*diameter;
        for j = -graphCellW-1:graphCellW
            x = j*diameter;
            rectangle('Position',[x,y,diameter,diameter]);       
        end
    end
    disp(occupiedX);
    for i = 1:length(occupiedX)
        for xi = -graphCellW-1:graphCellW
            if occupiedX(i) >= xi*diameter && occupiedX(i) <= xi*diameter + diameter
                x = xi*diameter;
                break;
            end
        end
        for yi = -graphCellH-1:graphCellH-1
            if occupiedY(i) >= yi*diameter && occupiedY(i) <= yi*diameter + diameter
                y = yi*diameter;
                break;
            end
        end
        disp(x);
        disp(y);
        rectangle('Position',[x,y,diameter,diameter],'FaceColor','b');
    end
    
end

% function to update position
function [globloc] = updatePosition(globloc, distance, angle)
    globloc(1) = globloc(1) + (distance * cos(globloc(3)));
    globloc(2) = globloc(2) + (distance * sin(globloc(3)));
    globloc(3) = globloc(3) + angle;
    globloc(3) = mod(globloc(3), 2.0*pi);
end