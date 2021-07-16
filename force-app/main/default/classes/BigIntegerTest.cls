@isTest
private class BigIntegerTest {
    /*
     * (c) 2021 Emmanuel Schweitzer and Salesforce, All Rights reserved.
     * Refer to the LICENSE at the root of this repository/project
     */

    
    static @isTest void testBasics() {
        System.assertEquals(true, BigInteger.ONE.equals(BigInteger.ONE));
        System.assertEquals(false, BigInteger.ONE.equals(BigInteger.ZERO));
        System.assertEquals(false, BigInteger.ONE.equals(null));
    }        
    
    static @isTest void testToString() {
        String ts = BigInteger.ZERO.toString(16);
        System.assertEquals('0', ts);

        ts = BigInteger.ONE.toString(16);
        System.assertEquals('1', ts);

        BigInteger b = new BigInteger('255', 10);
        System.assertEquals('ff', b.toString(16));

        b = new BigInteger('ff', 16);
        System.assertEquals('ff', b.toString(16));
        
        System.assertEquals('11111111', b.toString(2));
        System.assertEquals('255', b.toString(10));
        
        
        b = new BigInteger('39803983098349383749898', 10);
        ts = b.toString(16);
        System.assertEquals('86dc73b39686f56910a', ts);
    }
    
    static @isTest void testNegate() {
        BigInteger b = new BigInteger('340', 10);
        BigInteger c = b.negate();
        
        System.assertEquals(true, c.equals(new BigInteger('-340', 10))); 
        System.assertEquals(true, c.negate().equals(new BigInteger('340', 10)));         

        b = new BigInteger('-929083098387487497908309', 10);
        c = b.negate();
        
        System.assertEquals(true, c.equals(new BigInteger('929083098387487497908309', 10))); 
        System.assertEquals(true, c.negate().equals(b));         
    }

    static @isTest void testAbs() {
        BigInteger b = new BigInteger('340', 10);
        System.assertEquals(true, b.abs().equals(b)); 

        BigInteger c = new BigInteger('-340', 10);
        System.assertEquals(true, c.abs().equals(b));         
    }

    static @isTest void testMin() {
        BigInteger m422 = new BigInteger('-422', 10);
        BigInteger p302 = new BigInteger('302', 10);
        BigInteger pMost = new BigInteger('929083098387487497908309', 10);

        System.assertEquals(true, m422.min(p302).equals(m422));         
        System.assertEquals(true, p302.min(m422).equals(m422));                
        System.assertEquals(true, pMost.min(m422).equals(m422));                
    }

    static @isTest void testMax() {
        BigInteger m422 = new BigInteger('-422', 10);
        BigInteger p302 = new BigInteger('302', 10);

        System.assertEquals(true, m422.max(p302).equals(p302));         
        System.assertEquals(true, p302.max(m422).equals(p302));                
    }
    
    static @isTest void testCompareTo() {
        BigInteger mLots = new BigInteger('-92098283739676786387', 10);
        BigInteger mLess = new BigInteger('-8373967678', 10);
        BigInteger m422 = new BigInteger('-422', 10);
        BigInteger p302 = new BigInteger('302', 10);
        BigInteger pMore = new BigInteger('29810989083', 10);
        BigInteger pMost = new BigInteger('929083098387487497908309', 10);
        
        System.assertEquals(true, BigInteger.ZERO.compareTo(mLots) > 0);         
        System.assertEquals(true, BigInteger.ZERO.compareTo(mLess) > 0);         
        System.assertEquals(true, BigInteger.ZERO.compareTo(m422) > 0);         
        System.assertEquals(true, BigInteger.ZERO.compareTo(p302) < 0);         
        System.assertEquals(true, BigInteger.ZERO.compareTo(pMore) < 0);         
        System.assertEquals(true, BigInteger.ZERO.compareTo(pMost) < 0);         

        System.assertEquals(true, p302.compareTo(mLots) > 0);         
        System.assertEquals(true, mLots.compareTo(mLess) < 0);         
        System.assertEquals(true, pMost.compareTo(m422) > 0);         
        System.assertEquals(true, mLess.compareTo(p302) < 0);         
        System.assertEquals(true, m422.compareTo(pMore) < 0);         
        System.assertEquals(true, pMore.compareTo(pMost) < 0);         
    }
    
    static @isTest void testBitAnd() {
        BigInteger mask1 = new BigInteger('fffffffffffff3', 16);
        BigInteger mask2 = new BigInteger('f0', 16);
        BigInteger mask3 = new BigInteger('f0f0f0f0f0f0f0f0f0f0', 16);
        
        System.assertEquals(true, new BigInteger('f', 16).bitAnd(mask1).equals(new BigInteger('3', 16)));         
        System.assertEquals(true, new BigInteger('cf', 16).bitAnd(mask2).equals(new BigInteger('c0', 16)));         
        System.assertEquals(true, new BigInteger('83cf', 16).bitAnd(mask2).equals(new BigInteger('c0', 16)));
        System.assertEquals(true, new BigInteger('c094fd0983da73fade32', 16).bitAnd(mask3).equals(new BigInteger('c090f00080d070f0d030', 16)));
    }

    static @isTest void testBitOr() {
        BigInteger mask1 = new BigInteger('3', 16);
        BigInteger mask2 = new BigInteger('f0', 16);
        BigInteger mask3 = new BigInteger('f0f0f0f0f0f0f0f0f0f0', 16);
        
        System.assertEquals(true, new BigInteger('f', 16).bitOr(mask1).equals(new BigInteger('f', 16)));        
        System.assertEquals(true, new BigInteger('cf', 16).bitOr(mask2).equals(new BigInteger('ff', 16)));         
        System.assertEquals(true, new BigInteger('83cf', 16).bitOr(mask2).equals(new BigInteger('83ff', 16)));
        System.assertEquals(true, new BigInteger('c094fd0983da73fade32', 16).bitOr(mask3).equals(new BigInteger('f0f4fdf9f3faf3fafef2', 16)));
    }

    static @isTest void testBitXor() {
        BigInteger mask1 = new BigInteger('3', 16);
        BigInteger mask2 = new BigInteger('f0', 16);
        BigInteger mask3 = new BigInteger('f0f0f0f0f0f0f0f0f0f0', 16);
        
        System.assertEquals(true, new BigInteger('f', 16).bitXor(mask1).equals(new BigInteger('c', 16)));        
        System.assertEquals(true, new BigInteger('cf', 16).bitXor(mask2).equals(new BigInteger('3f', 16)));         
        System.assertEquals(true, new BigInteger('83cf', 16).bitXor(mask2).equals(new BigInteger('833f', 16)));
        System.assertEquals(true, new BigInteger('c094fd0983da73fade32', 16).bitXor(mask3).equals(new BigInteger('30640df9732a830a2ec2', 16)));
    }

    static @isTest void testBitAndNot() {
        BigInteger mask1 = new BigInteger('3', 16);
        BigInteger mask2 = new BigInteger('f0', 16);
        BigInteger mask3 = new BigInteger('f0f0f0f0f0f0f0f0f0f0', 16);
        
        System.assertEquals(true, new BigInteger('f', 16).bitAndNot(mask1).equals(new BigInteger('c', 16)));        
        System.assertEquals(true, new BigInteger('cf', 16).bitAndNot(mask2).equals(new BigInteger('f', 16)));         
        System.assertEquals(true, new BigInteger('83cf', 16).bitAndNot(mask2).equals(new BigInteger('830f', 16)));
        System.assertEquals(true, new BigInteger('c094fd0983da73fade32', 16).bitAndNot(mask3).equals(new BigInteger('40d09030a030a0e02', 16)));
    }

    static @isTest void testBitNot() {
        System.assertEquals(true, new BigInteger('f', 16).bitNot().equals(new BigInteger('-10', 16)));        
        System.assertEquals(true, new BigInteger('cf', 16).bitNot().equals(new BigInteger('-d0', 16)));         
        System.assertEquals(true, new BigInteger('83cf', 16).bitNot().equals(new BigInteger('-83d0', 16)));
        System.assertEquals(true, new BigInteger('c094fd0983da73fade32', 16).bitNot().equals(new BigInteger('-c094fd0983da73fade33', 16)));
    }
    
    static @isTest void testBitLength() {
        System.assertEquals(0, BigInteger.ZERO.bitLength());         
        System.assertEquals(4, new BigInteger('f', 16).bitLength());         
        System.assertEquals(8, new BigInteger('cf', 16).bitLength());         
        System.assertEquals(16, new BigInteger('83cf', 16).bitLength());
        System.assertEquals(80, new BigInteger('c094fd0983da73fade32', 16).bitLength());
        
        System.assertEquals(39, new BigInteger('-498398739873', 10).bitLength());      
    }
    
    static @isTest void testMod() {
        BigInteger p64 = new BigInteger('64', 10);
        BigInteger p66 = new BigInteger('66', 10);
        BigInteger p68 = new BigInteger('68', 10);
        BigInteger m68 = new BigInteger('-68', 10);
        BigInteger p2 = new BigInteger('2', 10);
        BigInteger p4 = new BigInteger('4', 10);
        BigInteger m4 = new BigInteger('-4', 10);
        BigInteger p8 = new BigInteger('8', 10);
        BigInteger m8 = new BigInteger('-8', 10);
        BigInteger pLotsEven = new BigInteger('38094094838973678364', 10);

        System.assertEquals(true, p64.mod(p4).equals(BigInteger.ZERO));
        System.assertEquals(true, p66.mod(p4).equals(p2));
        System.assertEquals(true, p68.mod(p4).equals(BigInteger.ZERO));
        System.assertEquals(true, p64.mod(p8).equals(BigInteger.ZERO));      
        System.assertEquals(true, p66.mod(p8).equals(p2));      
        System.assertEquals(true, p68.mod(p8).equals(p4));       
        System.assertEquals(true, p68.mod(m8).equals(p4));       
        System.assertEquals(true, m68.mod(m8).equals(new BigInteger('-12', 10)));       
        System.assertEquals(true, m68.mod(p8).equals(p4));       
        System.assertEquals(true, pLotsEven.mod(p2).equals(BigInteger.ZERO));
    }
    
    static @isTest void testModPowInt() {
        BigInteger p69 = new BigInteger('69', 10);
        BigInteger m69 = new BigInteger('-69', 10);
        BigInteger p4 = new BigInteger('4', 10);
        BigInteger m4 = new BigInteger('-4', 10);
        BigInteger p4569 = new BigInteger('4569', 10);
        BigInteger p149 = new BigInteger('149', 10);
        BigInteger pLotsEven = new BigInteger('38094094838973678364', 10);
        BigInteger pLotsOdd = new BigInteger('38094094838973678365', 10);
        
        System.assertEquals(true, p69.modPowInt(4, p4).equals(BigInteger.ONE));
        System.assertEquals(true, m69.modPowInt(4, p4).equals(BigInteger.ONE));
        System.assertEquals(true, p69.modPowInt(47589, p149).equals(new BigInteger('24', 10)));
        System.assertEquals(true, m69.modPowInt(3093030, m4).equals(BigInteger.ONE));
        System.assertEquals(true, p4569.modPowInt(4, p149).equals(new BigInteger('46', 10)));
        System.assertEquals(true, pLotsEven.modPowInt(4, p149).equals(BigInteger.ONE));
        System.assertEquals(true, pLotsOdd.modPowInt(4, p149).equals(new BigInteger('145', 10)));
    }
 
    static @isTest void testIntValue() {
        BigInteger m1 = new BigInteger('-1', 10);
        BigInteger p69 = new BigInteger('69', 10);
        BigInteger m69 = new BigInteger('-69', 10);
        BigInteger p4 = new BigInteger('4', 10);
        BigInteger m4 = new BigInteger('-4', 10);
        BigInteger p4569 = new BigInteger('4569', 10);
        BigInteger p149 = new BigInteger('149', 10);
        BigInteger pLots = new BigInteger('38094094838973678365', 10);
        BigInteger pMax31 = new BigInteger('2147483648', 10);
        BigInteger pMax31m1 = new BigInteger('2147483647', 10);
        
        System.assertEquals(0, BigInteger.ZERO.intValue());
        System.assertEquals(-1, m1.intValue());
        System.assertEquals(69, p69.intValue());
        System.assertEquals(-69, m69.intValue());
        System.assertEquals(4, p4.intValue());
        System.assertEquals(-4, m4.intValue());
        System.assertEquals(4569, p4569.intValue());
        System.assertEquals(149, p149.intValue());
        System.assertEquals(-988724451, pLots.intValue());
        //System.assertEquals(-2147483648, pMax31.intValue()); Illegal number in Apex Integer -- note discrepency
        System.assertEquals(2147483647, pMax31m1.intValue());
    }
    
    static @isTest void testByteValue() {
        BigInteger p69 = new BigInteger('69', 10);
        BigInteger m69 = new BigInteger('-69', 10);
        BigInteger p4 = new BigInteger('4', 10);
        BigInteger m4 = new BigInteger('-4', 10);
        BigInteger p4569 = new BigInteger('4569', 10);
        BigInteger p149 = new BigInteger('149', 10);
        BigInteger pLots = new BigInteger('38094094838973678365', 10);
        BigInteger pMax31 = new BigInteger('2147483648', 10);
        BigInteger pMax31m1 = new BigInteger('2147483647', 10);
        
        System.assertEquals(69, p69.byteValue());
        System.assertEquals(-69, m69.byteValue());
        System.assertEquals(4, p4.byteValue());
        System.assertEquals(-4, m4.byteValue());
        System.assertEquals(-39, p4569.byteValue());
        System.assertEquals(-107, p149.byteValue());
        System.assertEquals(29, pLots.byteValue());
        System.assertEquals(0, pMax31.byteValue());
        System.assertEquals(-1, pMax31m1.byteValue());
    }

    static @isTest void testShortValue() {
        BigInteger p69 = new BigInteger('69', 10);
        BigInteger m69 = new BigInteger('-69', 10);
        BigInteger p4 = new BigInteger('4', 10);
        BigInteger m4 = new BigInteger('-4', 10);
        BigInteger p4569 = new BigInteger('4569', 10);
        BigInteger p149 = new BigInteger('149', 10);
        BigInteger pLots = new BigInteger('38094094838973678365', 10);
        BigInteger pMax31 = new BigInteger('2147483648', 10);
        BigInteger pMax31m1 = new BigInteger('2147483647', 10);
        
        System.assertEquals(69, p69.shortValue());
        System.assertEquals(-69, m69.shortValue());
        System.assertEquals(4, p4.shortValue());
        System.assertEquals(-4, m4.shortValue());
        System.assertEquals(4569, p4569.shortValue());
        System.assertEquals(149, p149.shortValue());
        System.assertEquals(17181, pLots.shortValue());
        System.assertEquals(0, pMax31.shortValue());
        System.assertEquals(-1, pMax31m1.shortValue());
    }

    static @isTest void testSigNum() {
        BigInteger p69 = new BigInteger('69', 10);
        BigInteger m69 = new BigInteger('-69', 10);
        BigInteger p4 = new BigInteger('4', 10);
        BigInteger m4 = new BigInteger('-4', 10);
        BigInteger p4569 = new BigInteger('4569', 10);
        BigInteger p149 = new BigInteger('149', 10);
        BigInteger pLots = new BigInteger('38094094838973678365', 10);
        BigInteger mLots = new BigInteger('-38094094838973678365', 10);
        BigInteger pMax31 = new BigInteger('2147483648', 10);
        
        System.assertEquals(1, p69.sigNum());
        System.assertEquals(-1, m69.sigNum());
        System.assertEquals(1, p4.sigNum());
        System.assertEquals(-1, m4.sigNum());
        System.assertEquals(1, p4569.sigNum());
        System.assertEquals(1, p149.sigNum());
        System.assertEquals(1, pLots.sigNum());
        System.assertEquals(-1, mLots.sigNum());
        System.assertEquals(1, pMax31.sigNum());
        System.assertEquals(0, BigInteger.ZERO.sigNum());
    }
    
    static @isTest void testShiftLeft() {
        System.assertEquals(true, new BigInteger('f', 16).shiftLeft(1).equals(new BigInteger('1e', 16)));        
        System.assertEquals(true, new BigInteger('f', 16).shiftLeft(-1).equals(new BigInteger('7', 16)));        
        System.assertEquals(true, new BigInteger('cf', 16).shiftLeft(2).equals(new BigInteger('33c', 16)));         
        System.assertEquals(true, new BigInteger('83cf', 16).shiftLeft(8).equals(new BigInteger('83cf00', 16)));
        System.assertEquals(true, new BigInteger('c094fd0983da73fade32', 16).shiftLeft(16).equals(new BigInteger('c094fd0983da73fade320000', 16)));
    }

    static @isTest void testShiftRight() {
        System.assertEquals(true, new BigInteger('f', 16).shiftRight(1).equals(new BigInteger('7', 16)));        
        System.assertEquals(true, new BigInteger('f', 16).shiftRight(-1).equals(new BigInteger('1e', 16)));        
        System.assertEquals(true, new BigInteger('cf', 16).shiftRight(2).equals(new BigInteger('33', 16)));         
        System.assertEquals(true, new BigInteger('83cf', 16).shiftRight(8).equals(new BigInteger('83', 16)));
        System.assertEquals(true, new BigInteger('c094fd0983da73fade32', 16).shiftRight(16).equals(new BigInteger('c094fd0983da73fa', 16)));
    }

    static @isTest void testGetLowestSetBit() {
        System.assertEquals(0, new BigInteger('f', 16).getLowestSetBit());        
        System.assertEquals(2, new BigInteger('fc', 16).getLowestSetBit());         
        System.assertEquals(4, new BigInteger('830', 16).getLowestSetBit());
        System.assertEquals(9, new BigInteger('c094fd0983da73fade3200', 16).getLowestSetBit());
        System.assertEquals(0, new BigInteger('-f', 16).getLowestSetBit());        
        System.assertEquals(86, new BigInteger('-c000000000000000000000', 16).getLowestSetBit());
    }

    static @isTest void testGetBitCount() {
        System.assertEquals(4, new BigInteger('f', 16).bitCount());        
        System.assertEquals(6, new BigInteger('fc', 16).bitCount());         
        System.assertEquals(3, new BigInteger('830', 16).bitCount());
        System.assertEquals(42, new BigInteger('c094fd0983da73fade3200', 16).bitCount());
        System.assertEquals(3, new BigInteger('-f', 16).bitCount());        
        System.assertEquals(87, new BigInteger('-c000000000000000000000', 16).bitCount());
    }

    static @isTest void testTestBit() {
        System.assertEquals(true, new BigInteger('f', 16).testBit(0));        
        System.assertEquals(false, new BigInteger('cf', 16).testBit(5));         
        System.assertEquals(false, new BigInteger('83cf', 16).testBit(16));
        System.assertEquals(false, new BigInteger('c094fd0983da73fade32', 16).testBit(55));
    }

    static @isTest void testSetBit() {
        System.assertEquals(true, new BigInteger('f', 16).setBit(0).equals(new BigInteger('f', 16)));        
        System.assertEquals(true, new BigInteger('cf', 16).setBit(5).equals(new BigInteger('ef', 16)));         
        System.assertEquals(true, new BigInteger('83cf', 16).setBit(16).equals(new BigInteger('183cf', 16)));
        System.assertEquals(true, new BigInteger('c094fd0983da73fade32', 16).setBit(55).equals(new BigInteger('c094fd8983da73fade32', 16)));
    }

    static @isTest void testClearBit() {
        System.assertEquals(true, new BigInteger('f', 16).clearBit(0).equals(new BigInteger('e', 16)));        
        System.assertEquals(true, new BigInteger('cf', 16).clearBit(5).equals(new BigInteger('cf', 16)));         
        System.assertEquals(true, new BigInteger('83cf', 16).clearBit(16).equals(new BigInteger('83cf', 16)));
        System.assertEquals(true, new BigInteger('c094fd0983da73fade32', 16).clearBit(55).equals(new BigInteger('c094fd0983da73fade32', 16)));
    }

    static @isTest void testFlipBit() {
        System.assertEquals(true, new BigInteger('f', 16).flipBit(0).equals(new BigInteger('e', 16)));        
        System.assertEquals(true, new BigInteger('cf', 16).flipBit(5).equals(new BigInteger('ef', 16)));         
        System.assertEquals(true, new BigInteger('83cf', 16).flipBit(16).equals(new BigInteger('183cf', 16)));
        System.assertEquals(true, new BigInteger('c094fd0983da73fade32', 16).flipBit(55).equals(new BigInteger('c094fd8983da73fade32', 16)));
        System.assertEquals(true, new BigInteger('c094fd0983da73fade32', 16).flipBit(51).equals(new BigInteger('c094fd0183da73fade32', 16)));
    }

    static @isTest void testEquals() {
        System.assertEquals(true, BigInteger.ZERO.equals(BigInteger.ZERO));
        System.assertEquals(true, BigInteger.ONE.equals(BigInteger.ONE));
        System.assertEquals(false, BigInteger.ZERO.equals(BigInteger.ONE));

        BigInteger b1 = new BigInteger('255', 10);
        BigInteger b2 = new BigInteger('ff', 16);

        System.assertEquals(true, b1.equals(b1));
        System.assertEquals(true, b2.equals(b2));
        System.assertEquals(true, b1.equals(b2));
        System.assertEquals(false, b1.equals(BigInteger.ZERO));

        b1 = new BigInteger('39803983098349383749898', 10);
        b2 = new BigInteger('86dc73b39686f56910a', 16);
        
        System.assertEquals(true, b1.equals(b1));
        System.assertEquals(true, b2.equals(b2));
        System.assertEquals(true, b1.equals(b2));
        System.assertEquals(false, b1.equals(BigInteger.ZERO));        
    }
      
    static @isTest void testAdd() {
        BigInteger result = BigInteger.ZERO.add(BigInteger.ONE);
        System.assertEquals(true, BigInteger.ONE.equals(result));

        result = BigInteger.ONE.add(BigInteger.ONE);
        System.assertEquals(true, result.equals(new BigInteger('2', 10)));     

        BigInteger m418 = new BigInteger('-418', 10);
        result = BigInteger.ONE.add(m418);
        System.assertEquals(true, result.equals(new BigInteger('-417', 10)));     

        BigInteger m200 = new BigInteger('-200', 10);
        result = m200.add(m418);
        System.assertEquals(true, result.equals(new BigInteger('-618', 10)));     

        BigInteger p100b = new BigInteger('100000000000', 10);
        result = p100b.add(BigInteger.ONE);
        System.assertEquals(true, result.equals(new BigInteger('100000000001', 10)));     
    }
    
    static @isTest void testSubtract() {
        BigInteger result = BigInteger.ONE.subtract(BigInteger.ZERO);
        System.assertEquals(true, BigInteger.ONE.equals(result));

        result = BigInteger.ONE.subtract(BigInteger.ONE);
        System.assertEquals(true, result.equals(BigInteger.ZERO));     

        BigInteger m418 = new BigInteger('-418', 10);
        result = BigInteger.ONE.subtract(m418);
        System.assertEquals(true, result.equals(new BigInteger('419', 10)));     

        BigInteger p200 = new BigInteger('200', 10);
        result = m418.subtract(p200);
        System.assertEquals(true, result.equals(new BigInteger('-618', 10)));     
    }
    
    
    static @isTest void testMultiply() {
        BigInteger result = BigInteger.ZERO.multiply(BigInteger.ONE);
        System.assertEquals(true, BigInteger.ZERO.equals(result));
        
        result = BigInteger.ONE.multiply(BigInteger.ONE);
        System.assertEquals(true, BigInteger.ONE.equals(result));

        BigInteger b = new BigInteger('255', 10);
        result = BigInteger.ZERO.multiply(b);
        System.assertEquals(true, BigInteger.ZERO.equals(result));
        
        result = BigInteger.ONE.multiply(b);
        System.assertEquals(true, b.equals(result));
        
        result = b.multiply(b);
        System.assertEquals(true, result.equals(new BigInteger('65025', 10)));
        
        b = new BigInteger('48948974987', 10);
        result = b.multiply(new BigInteger('987737289', 10));
        System.assertEquals(true, result.equals(new BigInteger('48348727852988190243', 10))); 
        
        result = b.multiply(new BigInteger('-987737289', 10));
        System.assertEquals(true, result.equals(new BigInteger('-48348727852988190243', 10)));        

        b = new BigInteger('-48948974987', 10);
        result = b.multiply(new BigInteger('-987737289', 10));
        System.assertEquals(true, result.equals(new BigInteger('48348727852988190243', 10))); 
    }

    static @isTest void testSquare() {
        BigInteger result = BigInteger.ZERO.square();
        System.assertEquals(true, BigInteger.ZERO.equals(result));
        
        result = BigInteger.ONE.square();
        System.assertEquals(true, BigInteger.ONE.equals(result));

        BigInteger b = new BigInteger('255', 10);
        result = b.square();
        System.assertEquals(true, new BigInteger('65025', 10).equals(result));
        
        b = new BigInteger('48948974987', 10);
        result = b.square();
        System.assertEquals(true, result.equals(new BigInteger('2396002152277951650169', 10))); 
        
        b = new BigInteger('-48948974987', 10);
        result = b.square();
        System.assertEquals(true, result.equals(new BigInteger('2396002152277951650169', 10))); 
    }

    static @isTest void testDivide() {
        BigInteger result = BigInteger.ZERO.divide(BigInteger.ONE);
        System.assertEquals(true, BigInteger.ZERO.equals(result));
        
        result = BigInteger.ONE.divide(BigInteger.ONE);
        System.assertEquals(true, BigInteger.ONE.equals(result));

        BigInteger b = new BigInteger('255', 10);
        result = BigInteger.ZERO.divide(b);
        System.assertEquals(true, BigInteger.ZERO.equals(result));
        
        result = BigInteger.ONE.divide(b);
        System.assertEquals(true, BigInteger.ZERO.equals(result));
        
        result = b.divide(b);
        System.assertEquals(true, BigInteger.ONE.equals(result));
        
        b = new BigInteger('48948974987', 10);
        result = b.divide(new BigInteger('187737289', 10));
        System.assertEquals(true, result.equals(new BigInteger('260', 10))); 
        
        result = b.divide(new BigInteger('-187737289', 10));
        System.assertEquals(true, result.equals(new BigInteger('-260', 10)));        

        b = new BigInteger('-48948974987', 10);
        result = b.divide(new BigInteger('-187737289', 10));
        System.assertEquals(true, result.equals(new BigInteger('260', 10))); 
    }

    static @isTest void testRemainder() {
        BigInteger result = BigInteger.ZERO.remainder(BigInteger.ONE);
        System.assertEquals(true, BigInteger.ZERO.equals(result));
        
        result = BigInteger.ONE.remainder(BigInteger.ONE);
        System.assertEquals(true, BigInteger.ZERO.equals(result));

        BigInteger b = new BigInteger('255', 10);
        result = BigInteger.ZERO.remainder(b);
        System.assertEquals(true, BigInteger.ZERO.equals(result));
        
        result = BigInteger.ONE.remainder(b);
        System.assertEquals(true, BigInteger.ONE.equals(result));
        
        result = b.remainder(b);
        System.assertEquals(true, BigInteger.ZERO.equals(result));
        
        b = new BigInteger('48948974987', 10);
        result = b.remainder(new BigInteger('187737289', 10));
        System.assertEquals(true, result.equals(new BigInteger('137279847', 10))); 
        
        result = b.remainder(new BigInteger('-187737289', 10));
        System.assertEquals(true, result.equals(new BigInteger('137279847', 10)));        

        b = new BigInteger('-48948974987', 10);
        result = b.remainder(new BigInteger('-187737289', 10));
        System.assertEquals(true, result.equals(new BigInteger('-137279847', 10))); 
    }

    static @isTest void testDivideAndRemainder() {
        BigInteger[] result = BigInteger.ZERO.divideAndRemainder(BigInteger.ONE);
        System.assertEquals(true, BigInteger.ZERO.equals(result[0]));
        System.assertEquals(true, BigInteger.ZERO.equals(result[1]));
    }

    static @isTest void testPow() {
        BigInteger p69 = new BigInteger('69', 10);
        BigInteger m69 = new BigInteger('-69', 10);
        BigInteger p4569 = new BigInteger('4569', 10);
        BigInteger pLotsEven = new BigInteger('38094094838973678364', 10);
        
        System.assertEquals(true, p69.pow(4).equals(new BigInteger('22667121', 10)));
        System.assertEquals(true, m69.pow(4).equals(new BigInteger('22667121', 10)));
        System.assertEquals(true, p69.pow(17).equals(new BigInteger('18215225100020464195180876374789', 10)));
        System.assertEquals(true, m69.pow(30).equals(new BigInteger('98d31e006cbc149a1397d575c08e3611792dc2bf056529', 16)));
        System.assertEquals(true, p4569.pow(4).equals(new BigInteger('435797397329121', 10)));
        System.assertEquals(true, pLotsEven.pow(4).equals(new BigInteger('2105865524385008478019194463784052096848217271725978264385348248291142198518016', 10)));
    }
    
    static @isTest void testModPow() {
        BigInteger p2 = new BigInteger('2', 10);
        BigInteger p69 = new BigInteger('69', 10);
        BigInteger m69 = new BigInteger('-69', 10);
        BigInteger p4 = new BigInteger('4', 10);
        BigInteger m4 = new BigInteger('-4', 10);
        BigInteger p4569 = new BigInteger('4569', 10);
        BigInteger p149 = new BigInteger('149', 10);
        BigInteger pLotsEven = new BigInteger('38094094838973678364', 10);
        BigInteger pLotsOdd = new BigInteger('38094094838973678365', 10);
        
        System.assertEquals(true, p69.modPow(p4, p4).equals(BigInteger.ONE));
        System.assertEquals(true, m69.modPow(p4, p4).equals(BigInteger.ONE));
        System.assertEquals(true, p69.modPow(new BigInteger('47589', 10), p149).equals(new BigInteger('24', 10)));
        System.assertEquals(true, p2.modPow(new BigInteger('524288', 10), p2).equals(BigInteger.ZERO));
        System.assertEquals(true, p2.modPow(new BigInteger('524289', 10), p2).equals(BigInteger.ZERO));
        System.assertEquals(true, p2.modPow(new BigInteger('281474976710656', 10), p2).equals(BigInteger.ZERO));
        System.assertEquals(true, p4569.modPow(p4, p149).equals(new BigInteger('46', 10)));
        System.assertEquals(true, pLotsEven.modPow(p4, p149).equals(BigInteger.ONE));
        System.assertEquals(true, pLotsOdd.modPow(p4, p149).equals(new BigInteger('145', 10)));
    }

    static @isTest void testGcd() {
        BigInteger p4 = new BigInteger('4', 10);
        BigInteger p17 = new BigInteger('17', 10);
        BigInteger p69 = new BigInteger('69', 10);
        BigInteger m69 = new BigInteger('-69', 10);
        BigInteger p4569 = new BigInteger('4569', 10);
        BigInteger pLotsEven = new BigInteger('38094094838973678364', 10);
        
        System.assertEquals(true, p69.gcd(p4).equals(BigInteger.ONE));
        System.assertEquals(true, p4.gcd(m69).equals(BigInteger.ONE));
        System.assertEquals(true, p69.gcd(p17).equals(BigInteger.ONE));
        System.assertEquals(true, p4569.gcd(p4).equals(BigInteger.ONE));
        System.assertEquals(true, pLotsEven.gcd(p17).equals(BigInteger.ONE));
    }

    static @isTest void testModInverse() {
        BigInteger p4 = new BigInteger('4', 10);
        BigInteger p17 = new BigInteger('17', 10);
        BigInteger p69 = new BigInteger('69', 10);
        BigInteger m69 = new BigInteger('-69', 10);
        BigInteger p4569 = new BigInteger('4569', 10);
        BigInteger pLotsEven = new BigInteger('38094094838973678364', 10);
        
        System.assertEquals(true, p69.modInverse(p4).equals(BigInteger.ONE));
        System.assertEquals(true, p69.modInverse(p17).equals(BigInteger.ONE));
        System.assertEquals(true, p4569.modInverse(p4).equals(BigInteger.ONE));
        System.assertEquals(true, pLotsEven.modInverse(p17).equals(new BigInteger('10', 10)));
    }

    static @isTest void testIsProbablePrime() {
        BigInteger p4 = new BigInteger('4', 10);
        BigInteger p17 = new BigInteger('17', 10);
        BigInteger p69 = new BigInteger('69', 10);
        BigInteger p7919 = new BigInteger('7919', 10);
        BigInteger pLotsOdd = new BigInteger('1125899839733759', 10);

        System.assertEquals(false, p4.isProbablePrime(10));
        System.assertEquals(true, p17.isProbablePrime(10));
        System.assertEquals(false, p69.isProbablePrime(10));
        System.assertEquals(true, p7919.isProbablePrime(10));
        System.assertEquals(true, pLotsOdd.isProbablePrime(10));
    }

}
