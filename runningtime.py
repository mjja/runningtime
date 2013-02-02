#!/usr/local/bin/python3
import math
import decimal
accelrate = float(input("Acceleration rate (m/s/s): "))
decelrate = float(input("Deceleration rate (m/s/s): "))
initspeed = float(input("Initial speed (km/h, blank=0): ") or 0)/3.6 #convert to m/s while we're at it
trainmaxspeed = float(input("Maximum speed of vehicle (km/h): "))
finalspeed = float(input("Final speed (km/h, blank=0): ") or 0)/3.6 #ditto
section=[]
while True:
	dist=input("Segment "+str(len(section)+1)+" length (km): ")
	if dist=="": break
	speedlimit=int(input("Speed limit (negative for curve radius, zero for line speed): ") or 0)
	if speedlimit>=0: speedlimit=speedlimit or trainmaxspeed
	elif speedlimit>=-240: speedlimit=30
	elif speedlimit>=-500: speedlimit=50
	elif speedlimit>=-700: speedlimit=65
	elif speedlimit>=-1000: speedlimit=80
	elif speedlimit>=-1800: speedlimit=160
	elif speedlimit>=-7000: speedlimit=250
	else: speedlimit=400
	print("Using speed limit",speedlimit)
	if section: section[-1].append(min(speedlimit,trainmaxspeed)/3.6)
	section.append([int(decimal.Decimal(dist)*1000),min(speedlimit,trainmaxspeed)/3.6]) #convert to meters and m/s and put them both into the array
if section: section[-1].append(finalspeed)
print()
tottime=0
for distance,maxspeed,nextspeed in section:
	finalspeed=min(nextspeed,maxspeed) #we're overwriting a variable here, to save recoding. But we're finished with the inputted value of finalspeed as it was put into the last entry of the list.
	acceltime = (maxspeed-initspeed)/accelrate
	acceldist = (maxspeed+initspeed)*acceltime/2
	deceltime = (maxspeed-finalspeed)/decelrate
	deceldist = (maxspeed+finalspeed)*deceltime/2
	cruisetime=0
	if acceldist+deceldist>distance: #Won't hit top speed
		#Step 1: Get us to the triangle. Cut off either accel or decel, whichever we need.
		minspeed=initspeed
		trispeed=initspeed
		stitchtime=0
		if initspeed<finalspeed: #Cut off a section of acceleration at the front
			trispeed=finalspeed
			stitchtime=(finalspeed-initspeed)/accelrate
		elif initspeed>finalspeed: #Cut off a section of deceleration at the back
			minspeed=finalspeed
			stitchtime=(initspeed-finalspeed)/decelrate
		stitchdist=(initspeed+finalspeed)/2*stitchtime;
		if stitchdist>distance: #You can't make it to the target speed.
			stitchdist=distance
			if initspeed<finalspeed:
				stitchtime=(math.sqrt(initspeed*initspeed+2*distance*accelrate)-initspeed)/accelrate
				trispeed=initspeed+stitchtime*accelrate
				finalspeed=trispeed
			else:
				stitchtime=(math.sqrt(initspeed*initspeed-2*distance*decelrate)-initspeed)/-decelrate
				trispeed=initspeed-stitchtime*decelrate
				finalspeed=trispeed
		tridist=distance-stitchdist
		#We're now working with just the triangle.
		acceldist=tridist*decelrate/(accelrate+decelrate)
		topspeed=math.sqrt(trispeed*trispeed + 2*acceldist*accelrate)
		acceltime=(topspeed-trispeed)/accelrate
		deceldist=tridist-acceldist
		deceltime=(topspeed-trispeed)/decelrate
		if initspeed<finalspeed: #Reattach stitch to the acceleration
			acceltime=acceltime+stitchtime
			acceldist=acceldist+stitchdist
		elif initspeed>finalspeed: #Reattach stitch to the deceleration
			deceltime=deceltime+stitchtime
			deceldist=deceldist+stitchdist
	else:
		cruisedist=distance-acceldist-deceldist
		cruisetime=cruisedist/maxspeed
	totaltime=int(acceltime+cruisetime+deceltime)
	tottime=tottime+totaltime
	print("Section ***, ",distance/1000,"km in ",totaltime," sec, ending at ",finalspeed*3.6,"km/h - total running time ",tottime,"sec")
