public class SecureRandom {
    /*
     * (c) 2021 Emmanuel Schweitzer and Salesforce, All Rights reserved.
     * Refer to the LICENSE at the root of this repository/project
     */

    class Arcfour {
        Integer i = 0;
        Integer j = 0;
        Integer[] s = new Integer[256];
        
        void init(Integer[] key) {
            for (Integer i = 0; i < 256; ++i) {
            	s[i] = i;
            }
            
            Integer j = 0;
            Integer t;
            
            for (i = 0; i < 256; ++i) {
                j = (j + s[i] + key[(Integer) Math.mod(i, key.size())]) & 255;
                t = s[i];
                s[i] = s[j];
                s[j] = t;
            }
            
            this.i = 0;
            this.j = 0;
        }
        
        Integer next() {
            Integer t;
            this.i = (this.i + 1) & 255;
            this.j = (this.j + s[this.i]) & 255;
            t = s[this.i];
            s[this.i] = s[this.j];
            s[this.j] = t;
            return s[(t + s[this.i]) & 255];
        }
    }
    
    Arcfour rngState;
    Integer[] rngPool;
    Integer rngPptr;
    Integer rngPsize = 256;
    
    // Mix in a 32-bit integer into the pool
    void rngSeedInt(Long x) {
        rngPool[rngPptr++] ^= (Integer) (x & 255);
        rngPool[rngPptr++] ^= (Integer) ((x >> 8) & 255);
        rngPool[rngPptr++] ^= (Integer) ((x >> 16) & 255);
        rngPool[rngPptr++] ^= (Integer) ((x >> 24) & 255);
        if (rngPptr >= rngPsize) {
        	rngPptr -= rngPsize;
        }
    }
    
    // Mix in the current time (w/milliseconds) into the pool
    void rngSeedTime() {
        rngSeedInt(DateTime.now().getTime());
    }
    
    public SecureRandom() {
        // Initialize the pool with junk if needed.
        if(rngPool == null) {
            rngPool = new Integer[rngPsize];
            rngPptr = 0;
            Integer t;

            while(rngPptr < rngPsize) {  // extract some randomness from Math.random()
                t = (Integer) Math.floor(65536 * Math.random());
                rngPool[rngPptr++] = t >>> 8;
                rngPool[rngPptr++] = t & 255;
            }
            rngPptr = 0;
            rngSeedTime();
        }
    }
    
    Integer rngGetByte() {
        if (rngState == null) {
            rngSeedTime();
            rngState = new Arcfour();
            rngState.init(rngPool);
            
            for (rngPptr = 0; rngPptr < rngPool.size(); ++rngPptr) {
                rngPool[rngPptr] = 0;
            }
            rngPptr = 0;
            //rng_pool = null;
        }
        // TODO: allow reseeding after first request
        return rngState.next();        
    }
    
    public void nextBytes(Integer[] ba) {
        for (Integer i = 0; i < ba.size(); ++i) {
            ba[i] = rngGetByte();
        }
    }

}
