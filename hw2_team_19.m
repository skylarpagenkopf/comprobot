% COMS4733 HW2 Team 19
% sap2147 - Skylar Pagenkopf
% rfl2119 - Rich Landy

function hw2_team_19(serPort)

    figure(1);
    xvalues = [0];
    yvalues = [0];
    thetavalues = [0];
    rho = [1];
    count = 2;
    
    % vars to track
    reachedGoal = 0;
    followingObstacle = 0;
    leftbumploc = 1;
    globloc = [0,0,0];
    goalloc = [4,0,0]; % goal is 4 meters in front of init position
    bumploc = [0,0,0]; % track most recent bump
    turnloc = [0,0,0]; % track the last turn loc

    % start going forward along line
    SetFwdVelAngVelCreate(serPort,0.2,0);
    
    while ~reachedGoal
        xvalues = [xvalues,globloc(1)];
        yvalues = [yvalues,globloc(2)];
        thetavalues = [thetavalues,globloc(3)];        
        rho = [rho,count];
        count = count + 1;
        figure(1);
        plot(xvalues,yvalues);
        xlim([-5,5]);
        ylim([-1,10]);
        set(gca,'xtick',-5:5);
        set(gca,'ytick',-1:10);
        
        drawnow;
         % update x,y position
         disp(globloc(1));
         distance = DistanceSensorRoomba(serPort);
         angle = AngleSensorRoomba(serPort);
         globloc = updatePosition(globloc, distance, angle);
         wall = WallSensorReadRoomba(serPort);
         [ BumpRight, BumpLeft, ~, ~, ~, BumpFront] = BumpsWheelDropsSensorsRoomba(serPort); % Read Bumpers
         if sqrt( (globloc(1) - bumploc(1))^2 + (globloc(2) - bumploc(2))^2 ) > .30
             leftbumploc = 1;
         end
         % if we reached the goal
         if sqrt( (globloc(1) - goalloc(1))^2 + (globloc(2) - goalloc(2))^2 ) <= .20
             disp('reached goal');
             reachedGoal = 1;
             SetFwdVelAngVelCreate(serPort,0,0);
             BeepRoomba(serPort);
         % if we bumped into an obstacle, begin following obstacle
         elseif BumpRight || BumpLeft || BumpFront
             disp('bump');
             followingObstacle = 1;
             leftbumploc = 0;
             turnAngle(serPort,0.2,45);
             bumploc(1) = globloc(1);
             bumploc(2) = globloc(2);
             bumploc(3) = globloc(3);
         % if we found the line and were following an obstacle, and have left the bump loc, turn towards the goal
         elseif followingObstacle && leftbumploc && abs(goalloc(2) - globloc(2)) <= .30
             disp('turn to goal');
             if sqrt( (globloc(1) - turnloc(1))^2 + (globloc(2) - turnloc(2))^2 ) <= .30
                 disp('robot is trapped');
                 SetFwdVelAngVelCreate(serPort,0,0);
                 BeepRoomba(serPort);
                 BeepRoomba(serPort);
                 break;
             end
             turnloc(1) = globloc(1);
             turnloc(2) = globloc(2);
             turnloc(3) = globloc(3);
             followingObstacle = 0;
             rot = atand((goalloc(2) - globloc(2))/(goalloc(1) - globloc(1)));
             turn = mod(rot - (globloc(3) * 57.2958), 360);
             if turn > 1 && turn < 359
                turnAngle(serPort,.2,turn);
             end
         % if we are following the wall, or following the line, just go
         % straight
         elseif followingObstacle && wall || ~followingObstacle
             disp('follow wall or line');
             SetFwdVelAngVelCreate(serPort,0.2,0);
         % if we are following the wall and found a corner, turn
         elseif followingObstacle && ~wall
             disp('go around corner');
             SetFwdVelAngVelCreate(serPort,0.2,-1);
         end
         pause(0.2);
    end
end

% function to update position
function [globloc] = updatePosition(globloc, distance, angle)
    globloc(1) = globloc(1) + (distance * cos(globloc(3)));
    globloc(2) = globloc(2) + (distance * sin(globloc(3)));
    globloc(3) = globloc(3) + angle;
    globloc(3) = mod(globloc(3), 2.0*pi);
end