/**
* Shared binary data manipulation functions for midi
**/

module midi.midiutil;

import std.range;
import std.traits;


auto getFront(R)(ref R range){
    auto f = range.front();
    range.popFront();
    return f;
}

T[] getFrontN(R, T = ElementType!R)(ref R range, size_t n){
    T[] f = range[0..n];
    range.popFrontN(n);
    return f;
}

As frontAs(As, R)(R range){
    As r;
    (cast(ubyte*)&r)[0..As.sizeof] = range[0..As.sizeof];
    return r;
}

As getFrontAs(As, R)(ref R range){
    As r;
    (cast(ubyte*)&r)[0..As.sizeof] = range.getFrontN(As.sizeof)[];
    return r;
}


void writeVarLen(ref ubyte[] buffer, uint value){
    uint buf;
    buf = value & 0x7F;

    while((value >>= 7)){
        buf <<= 8;
        buf |= ((value & 0x7F) | 0x80);
    }

    while(1){
        buffer ~= cast(ubyte)(buf & 0xFF);
        if(buf & 0x80){
            buf >>= 8;
        }
        else{
            break;
        }
    }
}

uint readVarLen(ref const(ubyte)[] buffer){
    uint value;
    ubyte c;

    value = buffer[0];
    buffer = buffer[1..$];

    if(value & 0x80){
        value &= 0x7F;
        do{
            c = buffer[0];
            buffer = buffer[1..$];
            value = (value << 7) + (c & 0x7F);
        }
        while(c & 0x80);
    }

    return value;
}

void flipEndian(T)(T* pData){
    static if(is(T == struct)){
        foreach(ref m; (*pData).tupleof){
            alias M = typeof(m);
            static if(M.sizeof > 1 && (is(M == struct) || std.traits.isNumeric!M || std.traits.isSomeChar!M)){
                flipEndian(&m);
            }
        }
    }
    else{
        T copy = *pData;

        ubyte* pBytes = cast(ubyte*)pData;
        const(ubyte)* pCopy = cast(const(ubyte)*)&copy;
        foreach(a; 0 .. T.sizeof){
            pBytes[a] = pCopy[T.sizeof-1-a];
        }
    }
}

version(LittleEndian){
    void hostToBigEndian(T)(T* x) { flipEndian(x); }
    void hostToLittleEndian(T)(T* x) {}
    void littleToHostEndian(T)(T* x) {}
    void bigToHostEndian(T)(T* x) { flipEndian(x); }
}
else version(BigEndian){
    void hostToBigEndian(T)(T* x) {}
    void hostToLittleEndian(T)(T* x) { flipEndian(x); }
    void littleToHostEndian(T)(T* x) { flipEndian(x); }
    void bigToHostEndian(T)(T* x) {}
}
else{
    static assert("Unknown endian!");
}