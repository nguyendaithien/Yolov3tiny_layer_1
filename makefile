#all:
#	xrun -access +rwc ./src/*.v ./tb/*.v 
#wave:
#	xrun -access +rwc ./src/*.v ./tb/*.v -gui & 
all:
		xrun -access +rwc -sv -linedebug \
				     -input "run.tcl" \
						 	     -f listfile.f

wave:
		xrun -access +rwc -sv -linedebug \
				     -input "wave.tcl" \
						 	     -gui *.v *.sv &

