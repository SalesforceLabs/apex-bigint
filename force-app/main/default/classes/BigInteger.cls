public class BigInteger {    
    /**
     * @description A basic Apex BigInteger library - subset useful for RSA encryption plus some other public methods
     * Based on Tom Wu's jsbn.js and jsbn2.js, http://www-cs-students.stanford.edu/~tjw/jsbn
     * (c) 2021 Emmanuel Schweitzer and Salesforce, All Rights reserved.
     * Refer to the LICENSE at the root of this repository/project
     */

    public class IllegalArgumentException extends Exception {}
    public class IllegalStateException extends Exception {}
	public class ParseException extends Exception {}
	public class ArithmeticException extends Exception {}  

    public interface BigIntegerOperation {
        Integer apply(Integer a, Integer b);
    }   
    
    public class BigIntegerOperationAnd implements BigIntegerOperation {
        public Integer apply(Integer a, Integer b) {
            return a & b;
        }
    }
    
    public class BigIntegerOperationOr implements BigIntegerOperation {
        public Integer apply(Integer a, Integer b) {
            return a | b;
        }
    }
    
    public class BigIntegerOperationXor implements BigIntegerOperation {
        public Integer apply(Integer a, Integer b) {
            return a ^ b;
        }
    }
    
    public class BigIntegerOperationAndNot implements BigIntegerOperation {
        public Integer apply(Integer a, Integer b) {
            return (a &~ b); // instead of a &~ b;
        }
    }
    
    /**
     * DB defines the useful number of bits in our 32 bit Integers used to depict a BigInteger.
     */

    private static final Integer DB = 30;
    private static final Integer DB_MINUS_1 = DB - 1;
    private static final Integer THIRTY_TWO_MINUS_DB = 32 - DB;
    private static final Double LN2_TIMES_DB = 0.6931471805599453 * DB;
    
    /**
     * DM is the bit mask of the useful part of the payload
     */
    
    private static final Integer DM = ((1 << DB) - 1);
    
    /**
     * DV is the bit mask for the sign
     */
    
    private static final Integer DV = ((1 << DB));
    
    /**
     * These constants are defined on the basis of the JavaScript primitive datatypes.
     * Number is a 64 bit data type based on IEEE 754 floating point with a 53 bit mantissa.
     * It's aligns fairly well with Apex's Double. 
     */

    private static final Integer BI_FP = 52;
    private static final Long FV = (Long) Math.pow(2, BI_FP);
    private static final Integer F1 = BI_FP - DB;
    private static final Integer F2 = 2 * DB - BI_FP;

    private static final String BI_RM = '0123456789abcdefghijklmnopqrstuvwxyz';
    private static Integer[] BI_RC = new Integer[255]; 
    private static Boolean initialised = false;
    
    public static final BigInteger ZERO = nbv(0);
    public static final BigInteger ONE = nbv(1);
    
    private Integer size; // size of array
    private Integer[] payload; // array
    private Integer sign; // sign
    
 
    static BigInteger nbi() {
        return new BigInteger(null, null, null);
    }
    
    static BigInteger nbv(Integer i) {
        BigInteger r = nbi();
        r.fromInt(i);
        return r;
    }
    
    public BigInteger(Integer a, Integer b, SecureRandom c) {
        init();
        if (a != null) {
	        this.fromNumber(a, b, c);
        } else {
            sign = 0;
            size = 0;
            payload = new List<Integer>();
        }
    }
    
    public BigInteger(String value, Integer base) {
        init();
        this.fromString(value, base);
    }

    public BigInteger(String value) {
        init();
        this.fromString(value, 256);
    }  
    
    private void init() {
        if (initialised) { return; }
        
        Integer rr = '0'.charAt(0), vv;

        for (vv = 0; vv <= 9; ++vv) {
            BI_RC[rr++] = vv;
        }
        rr = 'a'.charAt(0);
        for (vv = 10; vv < 36; ++vv) {
            BI_RC[rr++] = vv;
        }
        rr = 'A'.charAt(0);
        for (vv = 10; vv < 36; ++vv) {
            BI_RC[rr++] = vv;
        }
        
        initialised = true;
    }
    
    String int2char(Integer index) {
        return BI_RM.substring(index, index + 1);
    }
    
    Integer intAt(String s, Integer index) {
        Integer c = BI_RC[s.charAt(index)];
        return c == null ? -1 : c;
    }

    BigInteger copyTo(BigInteger r) {
        r.payload = payload.clone();       
        r.size = size;
        r.sign = sign;
        return this;
    }
    
    BigInteger fromInt(Integer x) {
		size = 1;
        payload = new Integer[1];
  		sign = ( x < 0 ) ? -1 : 0;
        
        if (x > 0) {
            payload[0] = x;
        } else if (x < -1) {
            payload[0] = x + DV;
        } else {
            size = 0;
        }

        return this;
	}
        
    BigInteger fromString(String strValue, Integer base) {
  		Integer k;
        switch on base {
            when 2 { k = 1; }
            when 4 { k = 2; }
            when 8 { k = 3; }
            when 16 { k = 4; }
            when 32 { k = 5; }
            when 256 { k = 8; }
            when else { this.fromRadix(strValue, base); return this; }
        }

        size = 0;
  		sign = 0;
  		Integer i = strValue.length();
        Boolean mi = false;
        Integer sh = 0;
        
        payload = new List<Integer>();
        
  		while (--i >= 0) {
    		Integer x = (k==8) ? strValue.charAt(i) & 255 : intAt(strValue, i);
    		if (x < 0) {
                if (strValue.charAt(i) == 45) {
                    mi = true;
                }
      			continue;
    		}
            
    		mi = false;
            
            if (sh == 0) {
      			payload.add(x);
                size++;
            } else if (sh + k > DB) {
      			payload[size - 1] |= (x & ((1 << (DB - sh)) - 1)) << sh;
      			payload.add((x >> (DB - sh)));
                size++;
            } else {
		        payload[size - 1] |= x << sh;
            }

    		sh += k;

            if (sh >= DB) {
                sh -= DB;
            }    
  		}
        
        if (k == 8 && (strValue.charAt(0) & 128) != 0) {
    		sign = -1;
            if (sh > 0) {
                payload[size - 1] |= ((1 << (DB - sh)) - 1) << sh;
            }
  		}
        
  		this.clamp();        
  		if (mi) { BigInteger.ZERO.subTo(this, this); }
        return this;
	}

    BigInteger clamp() {
  		Integer c = sign & DM;
        while (size > 0 && payload[size - 1] == c) {
            --size;
        }

        return this;
	}
    
    public String toString(Integer base) {
  		if (sign < 0) {
            return '-' + this.negate().toString(base); 
        }
        
		Integer k;
      
        switch on base {
            when 2 { k = 1; }
            when 4 { k = 2; }
            when 8 { k = 3; }
            when 16 { k = 4; }
            when 32 { k = 5; }
            when 256 { k = 8; }
            when else { return this.toRadix(base); }
        }

  		Integer km = (1 << k) - 1;
        integer i = size;        
        Integer p = DB - Math.mod((i * DB), k);
        Integer d;
        Boolean m = false;
        String r = '';

        if (i-- > 0) {
    		if (p < DB && (d = payload[i] >> p) > 0) {
                m = true;
                r = int2char(d);
            }
            
    		while (i >= 0) {               
            	if (p < k) {
                	d = (payload[i] & ((1 << p) - 1)) << (k - p);
                	d |= payload[--i] >> (p += DB - k);
              	} else {
                	d = (payload[i] >> (p -= k)) & km;
                	if (p <= 0) {
                        p += DB;
                        --i;
                    }
              	}
                
                if (d > 0) { m = true; }
                if (m) { r += int2char(d); }
    		}
  		}
        
  		return m ? r : '0';
	}

	public BigInteger negate() {
        BigInteger r = nbi();
        BigInteger.ZERO.subTo(this, r);
        return r;
    }

	public BigInteger abs() {
        return (this.sign < 0) ? this.negate() : this;
    }   

    public Integer compareTo(BigInteger a) {
        Integer r = sign - a.sign;
        if (r != 0) { return r; }
        
      	Integer i = size;
      	r = i - a.size;
        if (r != 0) { return (sign < 0) ? -r : r; }
        
        while (--i >= 0){
            r = payload[i] - a.payload[i];
            if (r != 0) { return r; }
        }
        
      	return 0;
    }    

    private Integer nbits(Long x) {
      	Integer r = 1;
        Long t;
        
      	if ((t = x >>> 16) != 0) {
            x = t;
            r += 16;
        }
        
      	if ((t = x >> 8) != 0) {
            x = t;
            r += 8;
        }
        
      	if ((t = x >> 4) != 0) {
            x = t;
            r += 4;
        }
        
      	if ((t = x >> 2) != 0) {
            x = t;
            r += 2; 
        }
        
      	if ((t = x >> 1) != 0) {
            x = t;
            r += 1;
        }
        
      	return r;
	}    
    
    public Integer bitLength() {
        if (size <= 0) { return 0; }
  		return DB * (size - 1) + nbits(payload[size - 1] ^ (sign & DM));
	}
    
    BigInteger dlShiftTo(Integer numberOfBits, BigInteger r) {
    	Integer i;       
        Integer rSize = size + numberOfBits;
        Integer[] rPayload = new Integer[rSize];
        
        for (i = size - 1; i >= 0; --i) {
            rPayload[i + numberOfBits] = payload[i];
        }
        
        for (i = numberOfBits - 1; i >= 0; --i) {
            rPayload[i] = 0;
        }

        r.payload = rPayload;
        r.size = rSize;
      	r.sign = sign;
        return this;
    }
    
    BigInteger drShiftTo(Integer numberOfBits, BigInteger r) {
        Integer rSize = Math.max(size - numberOfBits, 0);
        Integer[] rPayload = new Integer[rSize];

        for (Integer i = numberOfBits; i < size; ++i) {
            rPayload[i - numberOfBits] = payload[i];
        }
        
  		r.size = rSize;
        r.payload = rPayload;
  		r.sign = sign;
        return this;
	}
    
    BigInteger lShiftTo(Integer numberOfBits, BigInteger r) {
        Integer bs = Math.mod(numberOfBits, DB);
  		Integer cbs = DB - bs;
  		Integer bm = (1 << cbs) - 1;
  		Integer ds = (Integer) Math.floor(numberOfBits / DB);
        Integer c = (sign << bs) & DM;
        Integer rSize = size + ds + 1;
        Integer i;
        Integer[] rPayload = new Integer[rSize];
        
  		for (i = size - 1; i >= 0; --i) {
    		rPayload[i + ds + 1] = (payload[i] >> cbs) | c;
    		c = (payload[i] & bm) << bs;
  		}
        
        for (i = ds - 1; i >= 0; --i) {
            rPayload[i] = 0;
        }
        
		rPayload[ds] = c;
        r.payload = rPayload;
		r.size = rSize;
		r.sign = sign;
		r.clamp();
        return this;
	}

    // (protected) r = this >> n
	BigInteger rShiftTo(Integer numberOfBits, BigInteger r) {
  		r.sign = sign;
  		Integer ds = (Integer) Math.floor(numberOfBits / DB);
  		if (ds >= size) {
            r.size = 0;
            return this;
        }
        
        Integer bs = Math.mod(numberOfBits, DB);
  		Integer cbs = DB - bs;
  		integer bm = (1 << bs) - 1;
        
        Integer rSize = size - ds;
        Integer[] rPayload = new Integer[rSize];
        
  		rPayload[0] = payload[ds] >> bs;
  
        for (Integer i = ds + 1; i < size; ++i) {
    		rPayload[i - ds - 1] |= (payload[i] & bm) << cbs;
			rPayload[i - ds] = payload[i] >> bs;
        }
        
        if (bs > 0) {
            rPayload[size - ds - 1] |= (sign & bm) << cbs;
        }
        
        r.payload = rPayload;
  		r.size = rSize;
  		r.clamp();
        return this;
	}

    BigInteger subTo(BigInteger a, BigInteger r) {
  		Integer i = 0;
        Integer c = 0;
        Integer m = Math.min(a.size, size);
        
        List<Integer> rPayload = new List<Integer>();
        
  		while (i < m) {
    		c += payload[i] - a.payload[i];
    		rPayload.add(c & DM); i++;
    		c >>= DB;
  		}
        
  		if (a.size < size) {
    		c -= a.sign;
            
    		while (i < size) {
      			c += payload[i];
      			rPayload.add(c & DM); i++;
      			c >>= DB;
    		}
            
    		c += sign;
  		} else {
    		c += sign;
            
    		while (i < a.size) {
      			c -= a.payload[i];
      			rPayload.add(c & DM); i++;
      			c >>= DB;
    		}
            
    		c -= a.sign;
  		}
        
  		r.sign = (c < 0) ? -1 : 0;
        if (c < -1) {
            rPayload.add(DV + c); i++;
        } else if (c > 0) {
            rPayload.add(c); i++;
        }
        
  		r.size = i;
        r.payload = rPayload;
  		r.clamp();
        return this;
	}

    // (protected) r = this * a, r != this,a (HAC 14.12)
    // "this" should be the larger one if appropriate.
    BigInteger multiplyTo(BigInteger a, BigInteger r) {
        BigInteger x = this.abs();
        BigInteger y = a.abs();
        Integer i = x.size;
        
        Integer rSize = i + y.size;
        Integer[] rPayload = new Integer[rSize];
        
        while (--i >= 0) {
            rPayload[i] = 0;
        }
        
        for (i = 0; i < y.size; ++i) {
            rPayload[i + x.size] = x.am(0, y.payload[i], rPayload, i, 0, x.size);
        }
        
        r.sign = 0;
        r.payload = rPayload;
        r.size = rSize;

        r.clamp();
        
        if (sign != a.sign) {
            BigInteger.ZERO.subTo(r, r);
        }

        return this;
    }
    
    // (protected) r = this^2, r != this (HAC 14.16)
    BigInteger squareTo(BigInteger r) {
        BigInteger x = this.abs();
        Integer rSize = 2*x.size;
        Integer i = rSize;
        
        Integer[] rPayload = new Integer[rSize];
        
        while (--i >= 0) {
            rPayload[i] = 0;
        }

        for (i = 0; i < x.size - 1; ++i) {          
            Integer c = x.am(i, x.payload[i], rPayload, 2 * i , 0, 1);
            Integer vv = x.am(i + 1, 2 * x.payload[i], rPayload, 2 * i + 1, c, x.size - i - 1);
            rPayload[i + x.size] += vv;

            if (rPayload[i + x.size] >= DV) {
                rPayload[i + x.size] -= DV;
                rPayload[i + x.size + 1] = 1;
            }
        }
        
        if (rSize > 0) {
            rPayload[rSize - 1] += x.am(i, x.payload[i], rPayload, 2 * i, 0, 1);
        }
        
        r.payload = rPayload;
        r.size = rSize;
        r.sign = 0;
        r.clamp();
        return this;
    }

    // (protected) divide this by m, quotient and remainder to q, r (HAC 14.20)
	// r != q, this != m.  q or r may be null.
	BigInteger divRemTo(BigInteger m, BigInteger q, BigInteger r) {
  		BigInteger pm = m.abs();
  		if (pm.size <= 0) { return this; }
        
  		BigInteger pt = this.abs();
        
  		if (pt.size < pm.size) {
    		if (q != null) { q.fromInt(0); }
    		if (r != null) { this.copyTo(r); }
    		return this;
  		}
        
  		if (r == null) { r = nbi(); }
        
  		BigInteger y = nbi();
        Integer ts = sign;
        Integer ms = m.sign;
  		integer nsh = DB - nbits(pm.payload[pm.size - 1]);

        if (nsh > 0) {
            pm.lShiftTo(nsh, y);
            pt.lShiftTo(nsh, r);
        } else { 
            pm.copyTo(y);
            pt.copyTo(r); 
        }
        
        Integer ys = y.size;
        Long y0 = y.payload[ys - 1];
  
        if (y0 == 0) { return this; }
        
  		Long yt = y0 * (1 << F1) + ((ys > 1) ? y.payload[ys - 2] >> F2 : 0);
        Double d1 = (Double) FV / yt;
        Double d2 = (Double)(1 << F1) / yt;
        Long e = 1 << F2;
        Integer i = r.size;
        Integer j = i - ys;
        BigInteger t = (q == null) ? nbi() : q;
        
  		y.dlShiftTo(j, t);
  
        if (r.compareTo(t) >= 0) {
    		r.payload[r.size++] = 1;
    		r.subTo(t, r);
  		}
        
  		BigInteger.ONE.dlShiftTo(ys, t);
        t.subTo(y, y);	// "negative" y so we can replace sub with am later
        
        while (y.size < ys) {
            y.payload.add(0);
            y.size++;
        }
        
        while (--j >= 0) {
            // Estimate quotient digit
            Long qd = (r.payload[--i] == y0) ? DM : (Long) Math.floor(r.payload[i] * d1 + (r.payload[i - 1] + e) * d2);
            Integer res = y.am(0, qd, r.payload, j, 0, ys);

            r.payload[i] += res;
            if (r.payload[i] < qd) {
                y.dlShiftTo(j, t);
                r.subTo(t, r);

                while (r.payload[i] < --qd) {
                    r.subTo(t, r);
                }
            }
        }
        
        if (q != null) {
            r.drShiftTo(ys, q);
            if (ts != ms) { BigInteger.ZERO.subTo(q, q); }
        }
        
        r.size = ys;
        r.clamp();
        
        if (nsh > 0) {
            r.rShiftTo(nsh, r);	// Denormalize remainder
        }

        if (ts < 0) {
            BigInteger.ZERO.subTo(r, r);
        }

        return this;
    }
    
    // (public) this mod a
    public BigInteger mod(BigInteger a) {
        BigInteger r = nbi();
        
        this.abs().divRemTo(a, null, r);
        if (sign < 0 && r.compareTo(BigInteger.ZERO) > 0) {
            a.subTo(r, r);
        }
        
        return r;
    }

    // (protected) return "-1/this % 2^DB"; useful for Mont. reduction
    // justification:
    //         xy == 1 (mod m)
    //         xy =  1+km
    //   xy(2-xy) = (1+km)(1-km)
    // x[y(2-xy)] = 1-k^2m^2
    // x[y(2-xy)] == 1 (mod m^2)
    // if y is 1/x mod m, then y(2-xy) is 1/x mod m^2
    // should reduce x and y(2-xy) by m^2 at each step to keep size bounded.
    // JS multiply "overflows" differently from C/C++, so care is needed here.
    Integer invDigit() {
        if (size < 1) { return 0; }
        
        Integer x = payload[0];

        if ((x & 1) == 0) { return 0; }

        Integer y = x & 3;		// y == 1/x mod 2^2
        y = (y * (2 - (x & 15) * y)) & 15;	// y == 1/x mod 2^4
        y = (y * (2 - (x & 255) * y)) & 255;	// y == 1/x mod 2^8
        y = (y * (2 - (((x & 65535) * y) & 65535))) & 65535;	// y == 1/x mod 2^16
        // last step - calculate inverse mod DV directly;
        // assumes 16 < DB <= 32 and assumes ability to handle 48-bit ints
        y = Math.mod(y * (2 - x * Math.mod(y, DV)), DV);		// y == 1/x mod 2^dbits
        // we really want the negative inverse, and -DV < y < DV
        return (y > 0) ? DV - y: -y;
    }    

    // (protected) true iff this is even
    Boolean isEven() {
        return (size > 0 ? (payload[0] & 1) : sign) == 0;
    }

    // (protected) this^e, e < 2^32, doing sqr and mul with "r" (HAC 14.79)
    BigInteger exp(Long e, ModReduction z) {
        if (e > 4294967296L || e < 1) { return BigInteger.ONE; }
        
        BigInteger r = nbi();
        BigInteger r2 = nbi();
        BigInteger g = z.convert(this);
        BigInteger temp;
        Integer i = nbits(e) - 1;

        g.copyTo(r);
        
        while (--i >= 0) {
            z.sqrTo(r, r2);

            if ((e & (1 << i)) > 0) {
                z.mulTo(r2, g, r);
            } else {
                temp = r;
                r = r2;
                r2 = temp;
            }
        }
        
        return z.revert(r);
    }   
    
    // (public) this^e % m, 0 <= e < 2^32
    public BigInteger modPowInt(Integer e, BigInteger m) {
        return (e < 256 || m.isEven()) ? this.exp(e, new Classic(m)) : this.exp(e, new Montgomery(m));
    }
    
	public Object deepClone() { // APEX does not let you override clone
        BigInteger r = nbi();
        this.copyTo(r);
        return r;
    }

	// (public) return value as integer
	public Integer intValue() {
        if (sign < 0) {
            if (size == 1) {
                return payload[0] - DV;
            } else {
                if (size == 0) { return -1; }
            }
        } else if (size == 1) {
            return payload[0];
        } else if (size == 0) {
            return 0;
        }

        // assumes 16 < DB < 32
        return ((payload[1] & (( 1 << THIRTY_TWO_MINUS_DB) - 1)) << DB) | payload[0];
    }

	// (public) return value as byte
	public Integer byteValue() {
        return (size == 0) ? sign : (payload[0] << 24) >> 24;
    }

	// (public) return value as short (assumes DB>=16)
	public Integer shortValue() {
        return (size == 0) ? sign : (payload[0] << 16) >> 16;
    }

	// (protected) return x s.t. r^x < DV
	Integer chunkSize(Integer r) {
        return (Integer) Math.floor(LN2_TIMES_DB / Math.log(r));
    }

	// (public) -1 if this < 0, 0 if this == 0, 1 if this > 0
	public Integer sigNum() {
        if (sign < 0) {
            return -1;
        } else if (size <= 0 || (size == 1 && payload[0] <= 0)) {
            return 0;
        } else {
            return 1;
        }
	}

	// (protected) convert to radix string
	String toRadix(Integer b) {
        if (this.signum() == 0 || b < 2 || b > 36) { return '0'; }
        
  		Integer cs = this.chunkSize(b);
  		Integer a = (Integer) Math.pow(b, cs);
  		BigInteger d = nbv(a);
        BigInteger y = nbi();
        BigInteger z = nbi();
        String r = '';

  		this.divRemTo(d, y, z);
        
  		while (y.signum() > 0) {
    		r = String.valueOf(a + z.intValue()).substring(1) + r; // TODO no tostring with radix for integer
    		y.divRemTo(d, y, z);
  		}
        
  		return String.valueOf(z.intValue()) + r; // TODO Same: z.intValue().toString(b) + r;
	}

	// (protected) convert from radix string
	void fromRadix(String s, Integer b) {
  		this.fromInt(0);
 
        Integer cs = this.chunkSize(b);
  		Integer d = (Integer) Math.pow(b, cs);
        Integer j = 0;
        Integer w = 0;
        Boolean mi = false;
        
  		for (Integer i = 0; i < s.length(); ++i) {
    		Integer x = intAt(s, i);
    		if (x < 0) {
                if (s.substring(i, i+1) == '-' && this.signum() == 0) {
                    mi = true;
                }
      			continue;
    		}
            
    		w = b * w + x;
    
            if (++j >= cs) {
      			this.dMultiply(d);
      			this.dAddOffset(w, 0);
                j = 0;
                w = 0;
    		}
  		}
        
      	if (j > 0) {
        	this.dMultiply((Integer) Math.pow(b, j));
        	this.dAddOffset(w,0);
      	}
        
      	if (mi) {
            BigInteger.ZERO.subTo(this, this);
          }
    }


	// (protected) alternate constructor
	void fromNumber(Integer a, Integer b, SecureRandom c) {
        BigIntegerOperation opOr = new BigIntegerOperationOr();
        
        if (a < 2) {
            this.fromInt(1);
        } else {
      		this.fromNumber(a, c); // this.fromNumber(a, c);

            if (!this.testBit(a - 1)) {	// force MSB set
        		this.bitwiseTo(BigInteger.ONE.shiftLeft(a - 1), opOr, this);
            }

            if (this.isEven()) {
                this.dAddOffset(1, 0); // force odd
            }
            
            while (!this.isProbablePrime(b)) {
                this.dAddOffset(2, 0);

                if (this.bitLength() > a) {
                    this.subTo(BigInteger.ONE.shiftLeft(a - 1), this);
                } 
       		}
    	} 
	}
        
  	void fromNumber(Integer a, SecureRandom b) {
    	// new BigInteger(int,RNG)
        Integer t = a & 7;
    	Integer[] x = new Integer[(a >> 3)+1];
    	b.nextBytes(x);
        
        if (t > 0) {
            x[0] &= ((1 << t) - 1); 
        } else {
            x[0] = 0;
        }
        
        String s = String.fromCharArray(x);
    	this.fromString(s, 256);
  	}
    
    // TODO public bnToByteArray
     
    public Boolean equals(BigInteger a) { return a == null ? false : (this.compareTo(a) == 0); }
	public BigInteger min(BigInteger a) { return a == null ? this : ((this.compareTo(a) < 0) ? this : a); }
	public BigInteger max(BigInteger a) { return a == null ? this : ((this.compareTo(a) > 0) ? this : a); }

    void bitwiseTo(BigInteger a, BigIntegerOperation op, BigInteger r) {
  		Integer i;
        Integer f;
        Integer m = Math.min(a.size, size);
        
        Integer rSize = Math.max(a.size, size);
        Integer[] rPayload = new Integer[rSize];
        
        for (i = 0; i < m; ++i) {
            rPayload[i] = op.apply(payload[i], a.payload[i]);
        }
        
      	if (a.size < size) {
            f = a.sign & DM;
            
            for (i = m; i < size; ++i) {
                rPayload[i] = op.apply(payload[i], f);
            } 
            
            r.size = size;
	    } else {
            f = sign & DM;
            
            for (i = m; i < a.size; ++i) {
                rPayload[i] = op.apply(f, a.payload[i]);
            }
            
            r.size = a.size;
	    }
        
        r.payload = rPayload;
 		r.sign = op.apply(sign, a.sign);
    	r.clamp();
    }

    public BigInteger bitAnd(BigInteger a) {
        BigInteger r = nbi();
        this.bitwiseTo(a, new BigIntegerOperationAnd(), r);
        return r;
    }
    
    public BigInteger bitOr(BigInteger a) {
        BigInteger r = nbi();
        this.bitwiseTo(a, new BigIntegerOperationOr(), r);
        return r;
    }
    
    public BigInteger bitXor(BigInteger a) {
        BigInteger r = nbi();
        this.bitwiseTo(a, new BigIntegerOperationXor(), r);
        return r;
    }

    public BigInteger bitAndNot(BigInteger a) {
        BigInteger r = nbi();
        this.bitwiseTo(a, new BigIntegerOperationAndNot(), r);
        return r;
    }

    public BigInteger bitNot() {
    	BigInteger r = nbi();
        
        r.payload = new Integer[size];
        
        for (Integer i = 0; i < size; ++i) {
            r.payload[i] = (DM &~ payload[i]);
        }
        
      	r.size = size;
      	r.sign = ~sign;
      	return r;
    }

    public BigInteger shiftLeft(Integer n) {
  		BigInteger r = nbi();
        
        if (n < 0) {
            this.rShiftTo(-n, r);
        } else {
            this.lShiftTo(n, r);
        }
        
  		return r;
	}

    // (public) this >> n
    public BigInteger shiftRight(Integer n) {
    	BigInteger r = nbi();
        
        if (n < 0) {
            this.lShiftTo(-n, r); 
        } else {
            this.rShiftTo(n,r);
        }
        
      	return r;
    }
        
    Integer lbit(Integer x) {
  		if (x == 0) { return -1; }
        
  		Integer r = 0;

  		if ((x & 65535) == 0) { x >>= 16; r += 16; }
  		if ((x & 255) == 0) { x >>= 8; r += 8; }
  		if ((x & 15) == 0) { x >>= 4; r += 4; }
  		if ((x & 3) == 0) { x >>= 2; r += 2; }
  		if ((x & 1) == 0) { ++r; }
  		return r;
	}
    
    public Integer getLowestSetBit() {
        for (Integer i = 0; i < size; ++i) {
            if (payload[i] != 0) {
                return i * DB + lbit(payload[i]);
            }
        }
        
        if (sign < 0) { return size * DB; }  

  		return -1;
	}

    Integer cbit(Integer x) {
        Integer r = 0;
  		while (x != 0) {
            x &= x - 1;
            ++r;
        }
        
  		return r;
	}

	// (public) return number of set bits
	public Integer bitCount() {
  		Integer r = 0;
        Integer x = sign & DM;

        for (Integer i = 0; i < size; ++i) {
            r += cbit(payload[i] ^ x);
        }

  		return r;
	}   
    
    public Boolean testBit(Integer n) {
  		Integer j = (Integer) Math.floor(n/DB);  
        return (j >= size) ? (sign != 0) : ((payload[j] & (1 << (Math.mod(n, DB)))) != 0);
	}

	// (protected) this op (1<<n)
    BigInteger changeBit(Integer n, BigIntegerOperation op) {
        BigInteger r = BigInteger.ONE.shiftLeft(n);
  		this.bitwiseTo(r, op, r);
  		return r;
	}
    
	public BigInteger setBit(Integer n) { return this.changeBit(n, new BigIntegerOperationOr()); }
    public BigInteger clearBit(Integer n) { return this.changeBit(n, new BigIntegerOperationAndNot()); }
	public Biginteger flipBit(Integer n) { return this.changeBit(n, new BigIntegerOperationXor()); }
 
    void addTo(BigInteger a, BigInteger r) {
		Integer i = 0;
        Integer c = 0;
        Integer m = Math.min(a.size, size);   
        List<Integer> rPayload = new List<Integer>();
        
  		while (i < m) {
    		c += payload[i] + a.payload[i]; 
    		rPayload.add(c & DM); i++;
    		c >>= DB;
  		}

        if (a.size < size) {
    		c += a.sign;

            while (i < size) {
                c += payload[i];
                rPayload.add(c & DM);
                i++;
                c >>= DB;
            }

    		c += sign;
  		} else {
            c += sign;

            while (i < a.size) {
              c += a.payload[i];
              rPayload.add(c & DM); i++;
              c >>= DB;
            }

            c += a.sign;
        }
        
        r.sign = (c < 0)? -1 : 0;
        if (c > 0) {
        	rPayload.add(c);
            i++;
        } else  if (c < -1) {
            rPayload.add(DV + c);
            i++;
        }
        
        r.size = i;
        r.payload = rPayload;
        r.clamp();
	}

    // (public) this + a
    public BigInteger add(BigInteger a) {
        BigInteger r = nbi();
        this.addTo(a, r);
        return r; 
    }
    
    // (public) this - a
    public BigInteger subtract(BigInteger a) {
        BigInteger r = nbi();
        this.subTo(a, r);
        return r;
    }
    
    // (public) this * a
    public BigInteger multiply(BigInteger a) { 
        BigInteger r = nbi();
        this.multiplyTo(a, r);
        return r;
    }
    
    // (public) this^2
    public BigInteger square() {
        BigInteger r = nbi();
        this.squareTo(r);
        return r;
    }
    
    // (public) this / a
    public BigInteger divide(BigInteger a) {
        BigInteger r = nbi();
        this.divRemTo(a, r, null);
        return r;
    }
    
    // (public) this % a
    public BigInteger remainder(BigInteger a) {
        BigInteger r = nbi();
        this.divRemTo(a, null, r);
        return r;
    }

    public BigInteger[] divideAndRemainder(BigInteger a) {
    	BigInteger q = nbi();
        BigInteger r = nbi();
        this.divRemTo(a, q, r);
        return new BigInteger[] { q, r };
    }

	// (protected) this *= n, this >= 0, 1 < n < DV
	void dMultiply(Integer n) {
        if (payload.size() == size) {
            payload.add(this.am(0, n - 1, payload, 0, 0, size));
        } else {
	        payload[size] = this.am(0, n - 1, payload, 0, 0, size);
        }

        ++size;
  		this.clamp();
	}

	// (protected) this += n << w words, this >= 0
	void dAddOffset(Integer n, Integer w) {
  		if (n == 0) { return; }
        
        while (size <= w) {
	        if (payload.size() == size) {
            	payload.add(0);
        	} else {
            	payload[size++] = 0;
            }
        }
        
		payload[w] += n;
        
  		while (payload[w] >= DV) {
    		payload[w] -= DV;
            if (++w >= size) {
                if (payload.size() == size) {
            		payload.add(0);
        		} else {
            		payload[size++] = 0;
            	}
            }
    		++payload[w];
  		}
	}

	// (public) this^e
	public BigInteger pow(Integer e) { return this.exp(e, new NullExp()); }

    // (protected) r = lower n words of "this * a", a.t <= n
    // "this" should be the larger one if appropriate.
    BigInteger multiplyLowerTo(BigInteger a, Integer n, BigInteger r) {
        Integer i = Math.min(size + a.size, n);
        Integer j;        
        Integer rSize = i;
        Integer[] rPayload = new Integer[i];

        r.sign = 0; // assumes a,this >= 0
        
        while (i > 0) {
            rPayload[--i] = 0;
        }
        
        for (j = rSize - size; i < j; ++i) {          
        	rPayload[i + size] = this.am(0, a.payload[i], rPayload, i, 0, size);
        }
        
        for (j = Math.min(a.size, n); i < j; ++i) {
            this.am(0, a.payload[i], rPayload, i, 0, n - i);
        }
        
        r.size = rSize;
        r.payload = rPayload;
        r.clamp();

        return this;
    }    

    // (protected) r = "this * a" without lower n words, n > 0
	// "this" should be the larger one if appropriate.
    BigInteger multiplyUpperTo(BigInteger a, Integer n, BigInteger r) {
        --n;
        Integer rSize = size + a.size - n;
        Integer i = rSize;        
        Integer[] rPayload = new Integer[rSize];
        
        r.sign = 0; // assumes a,this >= 0

        while (--i >= 0) {
            rPayload[i] = 0; // r[i] = 0;
        }
        
        for (i = Math.max(n - size, 0); i < a.size; ++i) {
            rPayload[size + i - n] = this.am(n - i, a.payload[i], rPayload, 0, 0, size + i - n);
        }
        
        r.size = rSize;
        r.payload = rPayload;      
        r.clamp();
        r.drShiftTo(1, r);

        return this;
    }    
    
    // (public) this^e % m (HAC 14.85)
    public BigInteger modPow(BigInteger e, BigInteger m) {
        Integer i = e.bitLength();
        Integer k;
        BigInteger r = nbv(1);
        ModReduction z;
        
        if (i <= 0) {
            return r;
        } else if (i < 18) {
            k = 1;
        } else if (i < 48) {
            k = 3;
        } else if (i < 144) {
            k = 4;
        } else if (i < 768) {
            k = 5;
        } else {
            k = 6;
        }
        
        if (i < 8) {
    		z = new Classic(m);
        } else if (m.isEven()) {
            z = new Barrett(m);
        } else {
		    z = new Montgomery(m);
        }

        // precomputation
        Integer n = 3;
        Integer k1 = k-1;
        Integer km = (1 << k) - 1;
  		BigInteger[] g = new BigInteger[km + 1];

        g[1] = z.convert(this);
        if (k > 1) {
    		BigInteger g2 = nbi();
    		z.sqrTo(g[1], g2);
            
    		while (n <= km) {
      			g[n] = nbi();
      			z.mulTo(g2, g[n-2], g[n]);
      			n += 2;
    		}
  		}

        Integer j = e.size - 1;
        Integer w;
        Boolean is1 = true;
        BigInteger r2 = nbi();
        BigInteger t;
        
  		i = nbits(e.payload[j]) - 1;

  		while (j >= 0) {
            if (i >= k1) {
                w = (e.payload[j] >> (i - k1)) & km; 
            } else {
      			w = (e.payload[j] & ((1 << (i + 1)) - 1)) << (k1 - i);
                if (j > 0) {
                    w |= e.payload[j - 1] >> (DB + i - k1);
                }
    		}

    		n = k;
            
    		while ((w&1) == 0) {
                w >>= 1; --n;
            }
            
    		if ((i -= n) < 0) {
                i += DB;
                --j;
            }
            
    		if (is1) {
      			g[w].copyTo(r);
      			is1 = false;
    		} else {
      			while (n > 1) {
                    z.sqrTo(r, r2);
                    z.sqrTo(r2, r);
                    n -= 2;
                }
                
                if (n > 0) {
                    z.sqrTo(r, r2); 
                } else {
                    t = r;
                    r = r2;
                    r2 = t;
                }
                
      			z.mulTo(r2, g[w], r);
    		}

            while (j >= 0 && (e.payload[j] & (1 << i)) == 0) {
              	z.sqrTo(r, r2);
                t = r; 
                r = r2; 
                r2 = t;
                
              	if (--i < 0) {
                    i = DB_MINUS_1;
                    --j;
                }
            }
  		}
        
  		return z.revert(r);
	}
    
    // (public) gcd(this,a) (HAC 14.54)
    public BigInteger gcd(BigInteger a) {
        BigInteger x = (sign < 0) ? this.negate() : (BigInteger) this.deepClone();
        BigInteger y = (a.sign < 0) ? a.negate() : (BigInteger) a.deepClone();
        
        if (x.compareTo(y) < 0) {
            BigInteger t = x;
            x = y;
            y = t;
        }

        Integer i = x.getLowestSetBit();
        Integer g = y.getLowestSetBit();
        
        if (g < 0) { return x; }
        if (i < g) { g = i; }
        if (g > 0) {
            x.rShiftTo(g, x);
            y.rShiftTo(g, y);
        }
        
        while (x.signum() > 0) {
            if ((i = x.getLowestSetBit()) > 0) { x.rShiftTo(i,x); }
            if ((i = y.getLowestSetBit()) > 0) { y.rShiftTo(i,y); }
            
            if (x.compareTo(y) >= 0) {
                x.subTo(y,x);
                x.rShiftTo(1,x);
            } else {
                y.subTo(x,y);
                y.rShiftTo(1,y);
            }
        }
        
        if (g > 0) { y.lShiftTo(g,y); }
        return y;
    }
    
    // (protected) this % n, n < 2^26
    Long modInt(Long n) {
        if (n <= 0) { return 0; }
        
  		Long d = Math.mod(DV, n);
        Long r = (sign < 0) ? n - 1 : 0;
        
        if (size > 0) {
            if (d == 0) {
                r = Math.mod(payload[0], n);
            } else {
                for (Integer i = size - 1; i >= 0; --i) {
                    r = Math.mod(d * r + payload[i], n);
                }
            }
        }
        
        return r;
    }

    // (public) 1/this % m (HAC 14.61)
    public BigInteger modInverse(BigInteger m) {
        if (m.signum() < 0) { throw new ArithmeticException(); }
        
        Boolean ac = m.isEven();
        
        if ((this.isEven() && ac) || m.signum() == 0) {
            return BigInteger.ZERO;
        }
        
        BigInteger u = (BigInteger) m.deepClone();
        BigInteger v = (BigInteger) this.deepClone();
        BigInteger a = nbv(1);
        BigInteger b = nbv(0);
        BigInteger c = nbv(0);
        BigInteger d = nbv(1);
        
        while (u.signum() != 0) {
            while (u.isEven()) {
                u.rShiftTo(1, u);
                
                if (ac) {
                    if (!a.isEven() || !b.isEven()) { 
                        a.addTo(this, a);
                        b.subTo(m, b); 
                    }
                    a.rShiftTo(1, a);
                } else if (!b.isEven()) {
                    b.subTo(m, b);
                }
                b.rShiftTo(1, b);
            }
            
            while (v.isEven()) {
                v.rShiftTo(1, v);
                
                if (ac) {
                    if (!c.isEven() || !d.isEven()) { 
                        c.addTo(this, c); 
                        d.subTo(m, d); 
                    }
                    c.rShiftTo(1, c);
                } else if (!d.isEven()) {
                    d.subTo(m,d);
                }
                d.rShiftTo(1,d);
            }
            
            if (u.compareTo(v) >= 0) {
                u.subTo(v, u);
                if (ac) { a.subTo(c, a); }
                b.subTo(d,b);
            } else {
                v.subTo(u, v);
                if (ac) { c.subTo(a, c); }
                d.subTo(b, d);
            }
        }
        
        if (v.compareTo(BigInteger.ONE) != 0) { return BigInteger.ZERO; }
        if (d.compareTo(m) >= 0) { return d.subtract(m); }
        
        if (d.signum() < 0) {
            d.addTo(m, d);
        } else {
            return d;
        }
        
        if (d.signum() < 0) {
            return d.add(m);
        }
        
        return d;
    }
    
    Integer[] lowprimes = new Integer[] { 2,3,5,7,11,13,17,19,23,29,31,37,41,43,47,53,59,61,67,71,73,79,83,89,97,
        								  101,103,107,109,113,127,131,137,139,149,151,157,163,167,173,179,181,191,193,197,199,
        								  211,223,227,229,233,239,241,251,257,263,269,271,277,281,283,293,
        								  307,311,313,317,331,337,347,349,353,359,367,373,379,383,389,397,
        								  401,409,419,421,431,433,439,443,449,457,461,463,467,479,487,491,499,
        								  503,509,521,523,541,547,557,563,569,571,577,587,593,599,
        								  601,607,613,617,619,631,641,643,647,653,659,661,673,677,683,691,
        								  701,709,719,727,733,739,743,751,757,761,769,773,787,797,
        								  809,811,821,823,827,829,839,853,857,859,863,877,881,883,887,
        								  907,911,919,929,937,941,947,953,967,971,977,983,991,997 };
    Integer lplim = (1 << 26) / lowprimes[lowprimes.size() - 1];

    // (public) test primality with certainty >= 1-.5^t
    public Boolean isProbablePrime(Integer t) {
        Integer i;
        BigInteger x = this.abs();
        
        if (x.size == 1 && x.payload[0] <= lowprimes[lowprimes.size() - 1]) {
            for (i = 0; i < lowprimes.size(); ++i) {
                if (x.payload[0] == lowprimes[i]) {
                    return true;
                }
            }
            
            return false;
        }
        
        if (x.isEven()) { return false; }
        
        i = 1;
        while (i < lowprimes.size()) {
            Long m = lowprimes[i];
            Integer j = i + 1;
            
            while (j < lowprimes.size() && m < lplim) {
                m *= lowprimes[j++];
            }
            
            m = x.modInt(m);
            
            while (i < j) {
                if (Math.mod(m, lowprimes[i++]) == 0) {
                    return false;
                }
            }
        }
        
        return x.millerRabin(t);
    }   
    
    // (protected) true if probably prime (HAC 4.24, Miller-Rabin)
    Boolean millerRabin(Integer t) {
        BigInteger n1 = this.subtract(BigInteger.ONE);
        Integer k = n1.getLowestSetBit();
        
        if (k <= 0) { return false; }
        
        BigInteger r = n1.shiftRight(k);
        t = (t + 1) >> 1;
        
        if (t > lowprimes.size()) { t = lowprimes.size(); }
        
        BigInteger a = nbi();
        
        for (Integer i = 0; i < t; ++i) {
            //Pick bases at random, instead of starting at 2
            a.fromInt(lowprimes[(Integer) Math.floor(Math.random() * lowprimes.size())]);
            BigInteger y = a.modPow(r, this);
            
            if (y.compareTo(BigInteger.ONE) != 0 && y.compareTo(n1) != 0) {
                Integer j = 1;
                
                while (j++ < k && y.compareTo(n1) != 0) {
                    y = y.modPowInt(2, this);
                    if (y.compareTo(BigInteger.ONE) == 0) {
                        return false;
                    }
                }
                
                if (y.compareTo(n1) != 0) {
                    return false;
                }
            }
        }
        
        return true;
    }
    
    
    Integer am(Integer i, Long x, Integer[] w, Integer j, Long c, Integer n) {
		Integer xl = (Integer) (x & 32767); 
        Long xh = (x >> 15);
        
  		while (--n >= 0) {
            Long l = payload[i] & 32767;
    		Integer h = payload[i++] >> 15;
            Long m = xh * l + h * xl;
			l = xl * l + (((Integer) m & 32767) << 15) + w[j] + (Integer)(c & 1073741823);
            c = (l >> 30) + (m >> 15) + xh * h + (c >> 30);
    		w[j++] = (Integer)(l & 1073741823);
  		}

  		return (Integer)(c & 1073741823);        
    }
            

    interface ModReduction {
        BigInteger convert(BigInteger x);
        BigInteger revert(BigInteger x);
        void reduce(BigInteger x);
        void mulTo(BigInteger x, BigInteger y, BigInteger r);
        void sqrTo(BigInteger x, BigInteger r);
    }
    
    class Classic implements ModReduction {
        BigInteger m;
        
        public Classic(BigInteger m) {
            this.m = m;
        }

        public BigInteger convert(BigInteger x) {
  			if (x.sign < 0 || x.compareTo(m) >= 0) { return x.mod(m); }
            return x;
		}

        public BigInteger revert(BigInteger x) { return x; }
        public void reduce(BigInteger x) { x.divRemTo(m, null, x); }
        public void mulTo(BigInteger x, BigInteger y, BigInteger r) { x.multiplyTo(y, r); this.reduce(r); }
        public void sqrTo(BigInteger x, BigInteger r) {  x.squareTo(r); this.reduce(r); }
    }
    
    // Montgomery reduction
    class Montgomery implements ModReduction {
        BigInteger m;
        Integer mp;
        Integer mpl;
        Integer mph;
        Integer um;
        Integer mt2;
        
        public Montgomery(BigInteger m) {
            this.m = m;
            this.mp = m.invDigit();
            this.mpl = this.mp & 32767;
            this.mph = this.mp >> 15;
            this.um = (1 << (DB - 15)) - 1;
            this.mt2 = 2 * m.size;
		}

        public BigInteger convert(BigInteger x) {
  			BigInteger r = nbi();
            
  			x.abs().dlShiftTo(m.size, r);
  			r.divRemTo(m, null, r);
            
            if (x.sign < 0 && r.compareTo(BigInteger.ZERO) > 0) {
                m.subTo(r, r);
            }
            
  			return r;
		}

		public BigInteger revert(BigInteger x) {
            BigInteger r = nbi();
            x.copyTo(r);
            this.reduce(r);
            return r;
        }

		public void reduce(BigInteger x) {
            while (x.size <= mt2) {
                // pad x so am has enough room later
                x.payload.add(0);
                x.size++;
            }
            
            for (Integer i = 0; i < m.size; ++i) {
                // faster way of calculating u0 = x[i]*mp mod DV
                Integer j = x.payload[i] & 32767; // x[i] & 0x7fff;
                Integer u0 = (j * mpl + (((j * mph + (x.payload[i] >> 15) * mpl) & um) << 15)) & DM;

                // use am to combine the multiply-shift-add into one call
                j = i + m.size;
                x.payload[j] += m.am(0, u0, x.payload, i, 0, m.size);

                // propagate carry
                while (x.payload[j] >= DV) {
                    x.payload[j] -= DV;
                    x.payload[++j]++;
                }
            }
            
            x.clamp();
            x.drShiftTo(m.size, x);
            
            if (x.compareTo(m) >= 0) {
                x.subTo(m,x);
            }
        }

        public void sqrTo(BigInteger x, BigInteger r) { x.squareTo(r); this.reduce(r); }
		public void mulTo(BigInteger x, BigInteger y, BigInteger r) { x.multiplyTo(y, r); this.reduce(r); }
    }

    
    class Barrett implements ModReduction {
        private BigInteger r2;
        private BigInteger q3;
        private BigInteger mu;
        private BigInteger m;
        
        public Barrett(BigInteger m) {
            this.r2 = nbi();
            this.q3 = nbi();
            BigInteger.ONE.dlShiftTo(2 * m.size, this.r2);
            this.mu = this.r2.divide(m);
            this.m = m;
        }
    
        public BigInteger convert(BigInteger x) {
            if (x.sign < 0 || x.size > 2 * m.size) {
                return x.mod(m);
            } else if (x.compareTo(m) < 0) {
                return x;
            } else {
                BigInteger r = nbi();
                x.copyTo(r);
                this.reduce(r);
                return r;
            }
        }
    
        public BigInteger revert(BigInteger x) {
            return x;
        }
    
        // x = x mod m (HAC 14.42)
        public void reduce(BigInteger x) {
            x.drShiftTo(m.size - 1, r2);
            
            if (x.size > m.size + 1) {
                x.size = m.size + 1;
                x.clamp();
            }
            
            mu.multiplyUpperTo(r2, m.size + 1, q3);
            m.multiplyLowerTo(q3, m.size + 1, r2);
            
            while (x.compareTo(r2) < 0) {
                x.dAddOffset(1, m.size + 1);
            }
            
            x.subTo(r2, x);
            
            while (x.compareTo(m) >= 0) {
                x.subTo(m, x);
            }
        }
    
        // r = x^2 mod m; x != r
        public void sqrTo(BigInteger x, BigInteger r) {
            x.squareTo(r);
            this.reduce(r);
        }
    
        // r = x*y mod m; x,y != r
        public void mulTo(BigInteger x, BigInteger y, BigInteger r) {
            x.multiplyTo(y, r);
            this.reduce(r);
        }
    }
    
    class NullExp implements ModReduction {
        public BigInteger convert(BigInteger x) { return x; }
        public BigInteger revert(BigInteger x) { return x; }
        public void reduce(BigInteger x) { return; }
        public void multo(BigInteger x, BigInteger y, BigInteger r) { x.multiplyTo(y,r); }
        public void sqrTo(BigInteger x, BigInteger r) { x.squareTo(r); }
    }
}
