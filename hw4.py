import sys
import cv2
import math
from matplotlib import pyplot as plt
import networkx as nx

diameter = .35

TURN_LEFT, TURN_RIGHT, TURN_NONE = (1, -1, 0)

def turn(p, q, r):
    return cmp((q[0] - p[0])*(r[1] - p[1]) - (r[0] - p[0])*(q[1] - p[1]), 0)

def _keep_left(hull, r):
    while len(hull) > 1 and turn(hull[-2], hull[-1], r) != TURN_LEFT:
            hull.pop()
    if not len(hull) or hull[-1] != r:
        hull.append(r)
    return hull

def convex_hull(points):
    """Returns points on convex hull of an array of points in CCW order."""
    points = sorted(points)
    l = reduce(_keep_left, points, [])
    u = reduce(_keep_left, reversed(points), [])
    return l.extend(u[i] for i in xrange(1, len(u) - 1)) or l

def getCircle(r, n):
    return [(math.cos(2*math.pi/n*x)*r,math.sin(2*math.pi/n*x)*r) for x in xrange(0,n+1)]

def getStartAndGoal(file):
	f = open(file)
	lines = f.readlines()
	line = lines[0].strip('\n').split(' ')
	start = (float(line[0]), float(line[1]))
	line = lines[1].strip('\n').split(' ')
	goal = (float(line[0]), float(line[1]))
	f.close()
	return start, goal

def getObstacles(file):
	obstacles = []
	f = open(file)
	lines = f.readlines()
	num = int(lines[0])
	lines = lines[1:len(lines)]
	# for each obstacle
	for i in xrange(0,num):
		obstacle = []
		vertices = int(lines[0])
		lines = lines[1:len(lines)]
		for j in xrange(0,vertices):
			line = lines[0].strip('\n').split(' ')
			obstacle.append((float(line[0]),float(line[1])))
			lines = lines[1:len(lines)]
		obstacles.append(obstacle)
	return obstacles

def growObstacles(obstacles):
	# robot = [(-.175,-.175),(-.175,.175),(.175,.175),(.175,-.175)]
	robot = getCircle(diameter/2, 8)
	robotreflected = [(-x,-y) for (x,y) in robot]
	grownobstacles = []
	grownvertices = []
	# get all new points
	for obs in obstacles:
		grownvert = []
		for (x,y) in obs:
			for (xd,yd) in robot:
				grownvert.append((x+xd,y+yd))
		grownvertices.append(grownvert)
	# find the convex hull
	for obs in grownvertices:
		hull = convex_hull(obs)
		grownobstacles.append(hull)
	return grownobstacles

def getVisibilityGraph(grownobstacles, start, goal, obstacles):
	edges = []
	grownedges = []
	# put start and end as obstacles
	grownobstacles = list(grownobstacles)
	grownobstacles.append([start])
	grownobstacles.append([goal])
	# also add obstacle edges for the interior check
	for i in xrange(0, len(obstacles)):
		for j in xrange(0,len(obstacles[i])):
			(x1, y1) = obstacles[i][j]
			if j == len(obstacles[i]) - 1:
				(x2, y2)= obstacles[i][0]
			else:
				(x2, y2) = obstacles[i][j+1]
			grownedges.append(((x1,y1), (x2,y2)))
	# get grown edges and get edges from one obstacle to every other obstacle
	for o1 in xrange(0, len(grownobstacles)):
		obs1 = grownobstacles[o1]
		for i in xrange(0,len(obs1)):
			(x1, y1) = obs1[i]
			if i == len(obs1) - 1:
				(x2, y2)= obs1[0]
			else:
				(x2, y2) = obs1[i+1]
			grownedges.append(((x1,y1), (x2,y2)))
			edges.append(((x1,y1), (x2,y2)))
		for o2 in xrange(o1+1, len(grownobstacles)):
			obs2 = grownobstacles[o2]
			for i in xrange(0,len(obs1)):
				(x1, y1) = obs1[i]
				for j in xrange(0, len(obs2)):
					(x2, y2) = obs2[j]
					# only add the edge if it's not interior to the obstacles
					if not isinterior(obs1, obs2, [(x1,y1),(x2,y2)], grownobstacles):
						edges.append(((x1,y1), (x2,y2)))
	# find intersections and delete
	i = 0
	while i < len(edges):
		for grownedge in grownedges:
			if edges[i] != grownedge and edges[i][0] != grownedge[0] and edges[i][0] != grownedge[1] and edges[i][1] != grownedge[0] and edges[i][1] != grownedge[1] and intersects(edges[i], grownedge):
				edges.pop(i)
				i -= 1
				break
		i += 1
	return edges

def isinterior(obs1, obs2, edge, grownobstacles):
	temp1 = obs1 + edge
	temp2 = obs2 + edge
	if convex_hull(temp1) != convex_hull(obs1) and convex_hull(temp2) != convex_hull(obs2):
		for obs in grownobstacles:
			temp3 = obs + edge
			if obs != obs1 and obs != obs2 and convex_hull(temp3) == convex_hull(obs):
				return False
		return True
	else:
		return True

def intersects(l1, l2):
	p1, q1 = l1
	p2, q2 = l2
	o1 = orientation(p1, q1, p2)
	o2 = orientation(p1, q1, q2)
	o3 = orientation(p2, q2, p1)
	o4 = orientation(p2, q2, q1)
	if o1 != o2 and o3 != o4:
		return True
	# colinearity
	if o1 == 0 and onsegment(p1, p2, q1) or o2 == 0 and onsegment(p1, q2, q1) or o3 == 0 and onsegment(p2, p1, q2) or o4 == 0 and onsegment(p2, q1, q2):
		return True
	return False

def orientation(p, q, r):
	val = (q[1]-p[1]) * (r[0]-q[0]) - (q[0]-p[0]) * (r[1]-q[1])
	if val == 0:
		return 0
	if val > 0:
		return 1
	else:
		return 2

def onsegment(p, q, r):
	if q[0] <= max(p[0], r[0]) and q[0] >= min(p[0], r[0]) and q[1] <= max(p[1], r[1]) and q[1] >= min(p[1], r[1]):
		return True
	return False

def getPath(edges, start, goal):
	G = nx.Graph()
	for edge in edges:
		v1, v2 = edge
		G.add_edge(v1, v2, weight=distance(v1, v2))
	# djikstra's
	return nx.shortest_path(G, start, goal, weight='weight')

def distance(p1,p2):
	return math.hypot(p2[0] - p1[0], p2[1] - p1[1])

# prints out the graph:
# obstacles are solid black line
# grown obstacles are dashed black line
# start is blue point
# goal is red point
# visibility is solid green lines
# shortest path is shown in red
if __name__ == '__main__':
	if len(sys.argv) != 3:
		print 'Usage: python hw4.py <obstaclefile> <startandgoalfile>'
		sys.exit(0)

	obstaclefile = sys.argv[1]
	startandgoalfile = sys.argv[2]

	start, goal = getStartAndGoal(startandgoalfile)
	obstacles = getObstacles(obstaclefile)
	grownobstacles = growObstacles(obstacles)
	visibilitygraph = getVisibilityGraph(grownobstacles, start, goal, obstacles)
	path = getPath(visibilitygraph, start, goal)

	# draw start
	plt.plot(start[0], start[1], 'bo')
	# draw goal
	plt.plot(goal[0], goal[1], 'ro')
	# draw obstacles
	for obs in obstacles:
		for i in xrange(0,len(obs)):
			(x1, y1) = obs[i]
			if i == len(obs) - 1:
				(x2, y2)= obs[0]
			else:
				(x2, y2) = obs[i+1]
			plt.plot([x1,x2], [y1,y2], 'k-')
	# draw visibility graph
	for edge in visibilitygraph:
		((x1,y1),(x2,y2)) = edge
		plt.plot([x1,x2], [y1,y2], 'g-')
	# draw grown obstacles
	for obs in grownobstacles:
		for i in xrange(0,len(obs)):
			(x1, y1) = obs[i]
			if i == len(obs) - 1:
				(x2, y2)= obs[0]
			else:
				(x2, y2) = obs[i+1]
			plt.plot([x1,x2], [y1,y2], 'k--')
	# draw the safe path
	for i in xrange(0,len(path)-1):
		(x1,y1) = path[i]
		(x2,y2) = path[i+1]
		plt.plot([x1,x2],[y1,y2], 'r-')
	# print path to console and show plot
	print path	
	plt.show()