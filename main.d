import std.stdio;
import core.time;
import midi.midifile;
void main() {
	string midifileName = "./test.mid";

	timer("parseFile", () => parseFile(midifileName) );
}

void parseFile(string midifileName){
	writefln("Parsing %s", midifileName);
	MIDIFile midifile = new MIDIFile(midifileName);
	
	writeln(midifile.ticksPerBeat);
	foreach(track; midifile.tracks){
		foreach(event; track){
			if(event.type == MIDIEventType.NoteOn){
				writeln(event.note.note);
			}
		}
	}
}


void timer(string funcName, void delegate() f){
	MonoTime before = MonoTime.currTime;
	writefln("Starting %s", funcName);
	f();

	MonoTime after = MonoTime.currTime;
    Duration timeElapsed = after - before;
	writefln("%s took %s", funcName, timeElapsed);	
}







