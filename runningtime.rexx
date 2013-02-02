/* */
say "Acceleration (m/s/s)"
pull accel
if accel="" then accel=.5
say "Deceleration (m/s/s)"
pull decel
if decel="" then decel=.5
say "Maximum speed (km/h)"
pull maxspeed
if maxspeed="" then maxspeed=400
i=1
do forever
	say "Track section "i": Enter length,speedlimit (0 for full line speed, negative for curve radius), blank to end, 'back' to delete the last entry"
	pull entry
	if entry="back" then do; i=i-1; iterate; end
	if entry="" then leave
	parse value entry with len","speedlimit
	select
		when speedlimit=0 then speedlimit=maxspeed
		when speedlimit<0 and speedlimit>=-241 then speedlimit=30
		when speedlimit<-241 and speedlimit>=-503 then speedlimit=50
		when speedlimit<-503 and speedlimit>=-704 then speedlimit=65
		when speedlimit<-704 and speedlimit>=-1006 then speedlimit=80
		when speedlimit<-1006 and speedlimit>=-1800 then speedlimit=160
		when speedlimit<-1800 and speedlimit>-7000 then speedlimit=250
		when speedlimit<=-7000 then speedlimit=400
		otherwise nop
	end
	if len=0 then iterate
	i=i+1
	len.i=len; speedlimit.i=speedlimit
end
len.0=i-1; speedlimit.0=i-1
	
initspeed=0
tottime=0
do j=1 to len.0
	nextsection=j+1
	if nextsection>len.0 then finalspeed=0; else finalspeed=speedlimit.nextsection/3.6 /* m/s */
	initspeed=initspeed/3.6 /* m/s */
	maxspeed=speedlimit.j/3.6 /* m/s */
	distance=len.j*1000; /* m */
	acceltime=(maxspeed-initspeed)/accel
	acceldist=(maxspeed+initspeed)*acceltime/2
	deceltime=(maxspeed-finalspeed)/decel
	deceldist=(maxspeed+finalspeed)*deceltime/2
	cruisetime=0
	if acceldist+deceldist>distance then do /* Won't hit top speed */
		/* Step 1: Get us to the triangle. Cut off either accel or decel, whichever we need. */
		minspeed=initspeed
		trispeed=initspeed
		stitchtime=0
		select
			when initspeed<finalspeed then do /* Cut off a section of acceleration at the front */
				trispeed=finalspeed
				stitchtime=(finalspeed-initspeed)/accel
			end
			when initspeed>finalspeed then do /* Cut off a section of deceleration at the back */
				minspeed=finalspeed
				stitchtime=(initspeed-finalspeed)/decel
			end
		end
		stitchdist=(initspeed+finalspeed)/2*stitchtime;
		if stitchdist>distance then do /* You can't make it to the target speed. */
			stitchdist=distance
			if initspeed<finalspeed then do /* TODO: Have less of these duplicated ifs. */
				stitchtime=(sqrt(initspeed*initspeed+2*distance*accel)-initspeed)/accel
				trispeed=initspeed+stitchtime*accel
				finalspeed=trispeed
			end
			else do
				stitchtime=(sqrt(initspeed*initspeed-2*distance*decel)-initspeed)/-decel
				trispeed=initspeed-stitchtime*decel
				finalspeed=trispeed
			end
		end
		tridist=distance-stitchdist
		/* We're now working with just the triangle. */
		acceldist=tridist*decel/(accel+decel)
		topspeed=sqrt(trispeed*trispeed + 2*acceldist*accel)
		acceltime=(topspeed-trispeed)/accel
		deceldist=tridist-acceldist
		deceltime=(topspeed-trispeed)/decel
		if initspeed<finalspeed then do /* Reattach stitch to the acceleration */
			acceltime=acceltime+stitchtime
			acceldist=acceldist+stitchdist
		end
		if initspeed>finalspeed then do /* Reattach stitch to the deceleration */
			deceltime=deceltime+stitchtime
			deceldist=deceldist+stitchdist
		end
	end
	else do
		cruisedist=distance-acceldist-deceldist
		cruisetime=int(cruisedist/maxspeed)
        end
	totaltime.j=int(acceltime+cruisetime+deceltime)
	tottime=tottime+totaltime.j
	say "Section "j", "len.j/1000"km in "totaltime.j" sec, ending at "finalspeed*3.6"km/h - total running time "tottime"sec"
	initspeed=finalspeed
end
