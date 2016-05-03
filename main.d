import std.stdio;
import core.time;
import midifile.midifile;
void main() {
	writeln("hello");

	MIDIFile midifile1 = new MIDIFile("./test.mid");

	MonoTime before = MonoTime.currTime;

	writeln(midifile1.ticksPerBeat);
	foreach(track; midifile1.tracks){
		foreach(event; track){
			if(event.type == MIDIEventType.NoteOn){
				writeln(event.note.note);
			}
		}
	}

	MonoTime after = MonoTime.currTime;
    Duration timeElapsed = after - before;
	writeln(timeElapsed);
}