/**
* Shared midi struct data structures
**/

module midi.mididata;

enum MIDIEventType : ubyte{
    NoteOff = 0x80,
    NoteOn = 0x90,
    KeyAfterTouch = 0xA0,
    ControlChange = 0xB0,
    ProgramChange = 0xC0,
    ChannelAfterTouch = 0xD0,
    PitchWheel = 0xE0,
    SYSEX = 0xF0,
    Custom = 0xFF
}

enum MIDIEvents : ubyte{
    SequenceNumber = 0x00, // Sequence Number
    Text = 0x01, // Text
    Copyright = 0x02, // Copyright
    TrackName = 0x03, // Sequence/Track Name
    Instrument = 0x04, // Instrument
    Lyric = 0x05, // Lyric
    Marker = 0x06, // Marker
    CuePoint = 0x07, // Cue Point
    PatchName = 0x08, // Program (Patch) Name
    PortName = 0x09, // Device (Port) Name
    EndOfTrack = 0x2F, // End of Track
    Tempo = 0x51, // Tempo
    SMPTE = 0x54, // SMPTE Offset
    TimeSignature = 0x58, // Time Signature
    KeySignature = 0x59, // Key Signature
    Custom = 0x7F, // Proprietary Event
}

struct MThd_Chunk{
    ubyte[4] id;   // 'M','T','h','d'
    uint     length;

    ushort   format;
    ushort   numTracks;
    ushort   ticksPerBeat;
}

struct MTrk_Chunk{
    ubyte[4] id;   // 'M','T','r','k'
    uint     length;
}


struct MIDIEvent{
    bool isEvent(MIDIEvents e){
        return type == MIDIEventType.Custom && subType == e;
    }

    struct Note{
        ubyte channel;
        int note;
        int velocity;
    }
    struct Tempo{
        int microsecondsPerBeat;
    }
    struct SMPTE{
        ubyte hours, minutes, seconds, frames, subFrames;
    }
    struct TimeSignature{
        ubyte numerator, denominator;
        ubyte clocks;
        ubyte d;
    }
    struct KeySignature{
        ubyte sf;
        ubyte minor;
    }

    uint tick;
    uint delta;
    ubyte type;
    ubyte subType;

    union{
        Note note;
        int sequenceNumber;
        string text;
        Tempo tempo;
        SMPTE smpte;
        TimeSignature timeSignature;
        KeySignature keySignature;
        immutable(ubyte)[] data;
    }
}