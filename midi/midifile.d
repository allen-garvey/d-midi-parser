//based on: https://github.com/TurkeyMan/dmidifile

module midi.midifile;

import midi.midiutil;
import midi.mididata;
import std.file;
import std.string;
import std.range;
import std.exception;
import std.traits;

class MIDIFile{
    this(const(char)[] filename){
        void[] file = enforce(read(filename), "Couldn't load .midi file!");
        this(cast(ubyte[])file);
    }

    this(const(ubyte)[] buffer){
        if(buffer[0..4] == "RIFF"){
            buffer.popFrontN(8);
            assert(buffer[0..4] == "RMID", "Not a midi file...");
            buffer.popFrontN(4);
        }

        MThd_Chunk *pHd = cast(MThd_Chunk*)buffer.ptr;

        assert(pHd.id[] == "MThd", "Not a midi file...");
        bigToHostEndian(pHd);

        format = pHd.format;
        ticksPerBeat = pHd.ticksPerBeat;
        tracks = new MIDIEvent[][pHd.numTracks];

        buffer.popFrontN(8 + pHd.length);

        // we will only deal with type 1 midi files here..
        assert(pHd.format == 1, "Invalid midi type.");

        for(size_t t = 0; t < pHd.numTracks && !buffer.empty; ++t){
            MTrk_Chunk *pTh = cast(MTrk_Chunk*)buffer.ptr;
            bigToHostEndian(pTh);

            buffer.popFrontN(MTrk_Chunk.sizeof);

            if(pTh.id[] == "MTrk"){
                const(ubyte)[] track = buffer[0..pTh.length];
                uint tick = 0;
                ubyte lastStatus = 0;

                while(!track.empty){
                    uint delta = readVarLen(track);
                    tick += delta;
                    ubyte status = track.getFront();

                    MIDIEvent ev;
                    bool appendEvent = true;

                    if(status == 0xFF){
                        // non-midi event
                        MIDIEvents type = cast(MIDIEvents)track.getFront();
                        uint bytes = readVarLen(track);

                        // get the event bytes
                        const(ubyte)[] event = track.getFrontN(bytes);

                        // read event
                        switch(type) with(MIDIEvents){
                            case SequenceNumber:{
                                static int sequence = 0;
                                if(!bytes)
                                    ev.sequenceNumber = sequence++;
                                else{
                                    ushort seq = event.getFrontAs!ushort;
                                    bigToHostEndian(&seq);
                                    ev.sequenceNumber = cast(int)seq;
                                }
                                break;
                            }
                            case Text:
                            case Copyright:
                            case TrackName:
                            case Instrument:
                            case Lyric:
                            case Marker:
                            case CuePoint:
                            case PatchName:
                            case PortName:{
                                ev.text = (cast(const(char)[])event).idup;
                                break;
                            }
                            case EndOfTrack:{
                                // is it valid to have data remaining after the end of track marker?
                                break;
                            }
                            case Tempo:{
                                ev.tempo.microsecondsPerBeat = event[0] << 16;
                                ev.tempo.microsecondsPerBeat |= event[1] << 8;
                                ev.tempo.microsecondsPerBeat |= event[2];
                                break;
                            }
                            case SMPTE:{
                                ev.smpte.hours = event[0];
                                ev.smpte.minutes = event[1];
                                ev.smpte.seconds = event[2];
                                ev.smpte.frames = event[3];
                                ev.smpte.subFrames = event[4];
                                break;
                            }
                            case TimeSignature:{
                                ev.timeSignature.numerator = event[0];
                                ev.timeSignature.denominator = event[1];
                                ev.timeSignature.clocks = event[2];
                                ev.timeSignature.d = event[3];
                                break;
                            }
                            case KeySignature:{
                                ev.keySignature.sf = event[0];
                                ev.keySignature.minor = event[1];
                                break;
                            }
                            case Custom:{
                                ev.data = event.idup;
                                break;
                            }
                            default:
                                // TODO: are there any we missed?
                                appendEvent = false;
                        }

                        if(appendEvent){
                            ev.subType = type;
                        }
                    }
                    else if(status == 0xF0){
                        uint bytes = readVarLen(track);

                        // get the SYSEX bytes
                        const(ubyte)[] event = track.getFrontN(bytes);
                        ev.data = event.idup;
                    }
                    else{
                        if(status < 0x80){
                            // HACK: stick the last byte we popped back on the front...
                            track = (track.ptr - 1)[0..track.length+1];
                            status = lastStatus;
                        }
                        lastStatus = status;

                        int eventType = status & 0xF0;

                        int param1 = readVarLen(track);
                        int param2 = 0;
                        if(eventType != MIDIEventType.ProgramChange && eventType != MIDIEventType.ChannelAfterTouch)
                            param2 = readVarLen(track);

                        switch(eventType){
                            case MIDIEventType.NoteOn:
                            case MIDIEventType.NoteOff:{
                                ev.note.channel = status & 0x0F;
                                ev.note.note = param1;
                                ev.note.velocity = param2;
                                break;
                            }
                            default:
                                // TODO: handle other event types?
                                appendEvent = false;
                        }
                    }

                    // append event to track
                    if(appendEvent){
                        ev.tick = tick;
                        ev.delta = delta;
                        ev.type = status != 0xFF ? status & 0xF0 : status;
                        if(status != 0xFF){
                            ev.subType = status & 0x0F;
                        }
                        tracks[t] ~= ev;
                    }
                }
            }

            buffer.popFrontN(pTh.length);
        }
    }

    int format;
    int ticksPerBeat;

    MIDIEvent[][] tracks;
}