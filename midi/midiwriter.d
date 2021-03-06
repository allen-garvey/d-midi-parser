module midi.midiwriter;

import midi.midifile;
import midi.midiutil;
import midi.mididata;


void writeMidiFile(string filename, MIDIEvent[][] tracks){

	
}


//Reference for MIDI spec:
//http://ccarh.org/courses/253/handout/smf/
MThd_Chunk createMidiHeaderChunk(ushort numTracks, ushort ticksPerBeat=256)
    out(header){
        assert(header.id[] == "MThd", "Incorrect midi header chunk id");
    }
    body{
        MThd_Chunk midiHeader;
        //id and length must always be set to the following values
        midiHeader.length = 6;
        //midi format 1 is multi-track, 0 is single track
        midiHeader.format = 1;
        midiHeader.numTracks = numTracks;
        midiHeader.ticksPerBeat = ticksPerBeat;

        //numeric values must be converted to big endian
        hostToBigEndian(&midiHeader);

        midiHeader.id = ['M', 'T', 'h', 'd'];

        return midiHeader;
    }

MTrk_Chunk createMidiTrackChunk(uint length)
    out(chunk){
        assert(chunk.id[] == "MTrk", "Incorrect midi track chunk id");
    }
    body{
        MTrk_Chunk trackChunk;
        trackChunk.length = length;
        hostToBigEndian(&trackChunk);

        trackChunk.id = ['M', 'T', 'r', 'k'];
        return trackChunk;
    }





