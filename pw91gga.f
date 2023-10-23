C
C ******************************************************************
C
C PERDEW WANG ROUTINES, SLIGHTLY OPTIMIZED
C
      SUBROUTINE PW91EX(DKF,S,U,V,EXL,EXN,VX)
C
C  GGA91 EXCHANGE FOR A SPIN-UNPOLARIZED ELECTRONIC SYSTEM
C  INPUT DKF: KF REFERRING TO DENSITY D
C  INPUT S:   ABS(GRAD D)/(2*KF*D)
C  INPUT U:   (GRAD D)*GRAD(ABS(GRAD D))/(D**2 * (2*KF)**3)
C  INPUT V:   (LAPLACIAN D)/(D*(2*KF)**2)
C  OUTPUT:    EXCHANGE ENERGY PER ELECTRON (LOCAL: EXL, NONLOCAL: EXN)
C             AND POTENTIAL (VX)
C
      IMPLICIT REAL*8 (A-H,O-Z)
      SAVE
      DATA A1,A2,A3,A4/0.19645D0,0.27430D0,0.15084D0,100.0D0/
      DATA AX,A,B1/-0.238732414D0,7.7956D0,0.004D0/
      DATA THRD4/1.3333333333333333D0/
      FAC = AX*DKF
      S2 = S*S
      S3 = S2*S
      S4 = S2*S2
      AS = A*S
      PA = SQRT(1.0D0+AS*AS)
      P0 = AS/PA
      P1 = A1*LOG(AS+PA)
      P2 = A3*EXP(-A4*S2)
      P3 = 1.0D0/(1.0D0+S*P1+B1*S4)
      P4 = 1.0D0+S*P1+(A2-P2)*S2
      F = P3*P4
      EXL = FAC 
      EXN = FAC*(F-1.0D0)
C
C  ENERGY DONE. NOW THE POTENTIAL:
C
      P5 = B1*S2-(A2-P2)
      P6 = S*(P1+A1*P0)
      P7 = 2*((A2-P2)+A4*S2*P2-2*B1*S2*F)
      FS = P3*(P3*P5*P6+P7)
      P8 = 2*S*(B1-A4*P2)
      P9 = P1+A1*P0*(3.0D0-P0*P0)
      P10 = 4*(A4*S*P2*(2.0D0-A4*S2)-2*B1*S*F-B1*S3*FS)
      P11 = P3*P3*(P1+A1*P0+4*B1*S3)
      FSS = P3*P3*(P5*P9+P6*P8)-2*P3*P5*P6*P11+P3*P10-P7*P11
      VX = FAC*(THRD4*F-(U-THRD4*S3)*FSS-V*FS)
      RETURN
      END
C
C
      SUBROUTINE PW91LC(RS,ZET,EC,VCUP,VCDN,ECRS,ECZET,ALFC)
C
C  UNIFORM-GAS CORRELATION OF PERDEW AND WANG 1991
C  INPUT: SEITZ RADIUS (RS), RELATIVE SPIN POLARIZATION (ZET)
C  OUTPUT: CORRELATION ENERGY PER ELECTRON (EC), 
C          UP- AND DOWN-SPIN POTENTIALS (VCUP,VCDN), 
C          DERIVATIVES OF EC VERSUS RS (ECRS) & ZET (ECZET),
C          CORRELATION CONTRIBUTION (ALFC) TO THE SPIN STIFFNESS 
C
      IMPLICIT REAL*8 (A-H,O-Z)
      DATA GAMR,FZZR/1.92366105D0,0.58482234D0/
      DATA THRD,THRD4/0.333333333333D0,1.333333333333D0/
      ZETPR = (1.0D0+ZET)**THRD
      ZETMR = (1.0D0-ZET)**THRD
      F = (ZETPR**4+ZETMR**4-2.0D0)*GAMR
      CALL GCOR(0.0310907D0,0.21370D0,7.5957D0,3.5876D0,1.6382D0,
     &          0.49294D0,RS,EU,EURS)
      CALL GCOR(0.01554535D0,0.20548D0,14.1189D0,6.1977D0,3.3662D0,
     &          0.62517D0,RS,EP,EPRS)
      CALL GCOR(0.0168869D0,0.11125D0,10.357D0,3.6231D0,0.88026D0,
     &          0.49671D0,RS,ALFM,ALFRSM)
C
C  ALFM IS MINUS THE SPIN STIFFNESS ALFC
C
      ALFC = -ALFM
      Z3 = ZET**3
      Z4 = Z3*ZET
      EC = EU*(1.0D0-F*Z4)+EP*F*Z4-ALFM*F*(1.0D0-Z4)*FZZR
C
C  ENERGY DONE. NOW THE POTENTIAL:
C
      ECRS = EURS*(1.0D0-F*Z4)+EPRS*F*Z4-ALFRSM*F*(1.0D0-Z4)*FZZR
      FZ = THRD4*(ZETPR-ZETMR)*GAMR
      ECZET = 4.0D0*Z3*F*(EP-EU+ALFM*FZZR)
     &      +FZ*(Z4*EP-Z4*EU-(1.0D0-Z4)*ALFM*FZZR)
      COMM = EC-RS*ECRS*THRD-ZET*ECZET
      VCUP = COMM + ECZET
      VCDN = COMM - ECZET
      RETURN
      END
C
C ******************************************************************
C
      SUBROUTINE GCOR(A,A1,B1,B2,B3,B4,RS,GG,GGRS)
C
C  CALLED BY SUBROUTINE PW91LC
C
      IMPLICIT REAL*8 (A-H,O-Z)
      SAVE
      Q0 = -2*A*(1.0D0+A1*RS)
      RS12 = SQRT(RS)
      RS32 = RS12**3
      Q1 = 2*A*(B1*RS12+B2*RS+B3*RS32+B4*RS*RS)
      Q2 = LOG(1.0D0+1.0D0/Q1)
      GG = Q0*Q2
      Q3 = A*(B1/RS12+2*B2+3*B3*RS12+4*B4*RS)
      GGRS = -2*A*A1*Q2-Q0*Q3/(Q1*Q1+Q1)
      RETURN
      END
C
C ******************************************************************
C
      SUBROUTINE PW91NC(RS,ZET,T,UU,VV,WW,H,DVCUP,DVCDN)
C
C  GGA91 CORRELATION
C  INPUT RS:  SEITZ RADIUS
C  INPUT ZET: RELATIVE SPIN POLARIZATION
C  INPUT T:   ABS(GRAD D)/(D*2*KS*G)
C  INPUT UU:  (GRAD D)*GRAD(ABS(GRAD D))/(D**2 * (2*KS*G)**3)
C  INPUT VV:  (LAPLACIAN D)/(D * (2*KS*G)**2)
C  INPUT WW:  (GRAD D)*(GRAD ZET)/(D * (2*KS*G)**2
C  OUTPUT H:  NONLOCAL PART OF CORRELATION ENERGY PER ELECTRON
C  OUTPUT DVCUP,DVCDN:  NONLOCAL PARTS OF CORRELATION POTENTIALS
C
      IMPLICIT REAL*8 (A-H,O-Z)
      COMMON/PW91GAS/G,EC,ECRS,ECZET
      SAVE
Cdvp  DATA XNU,CC0,CX,ALF/15.75592D0,0.004235D0,-0.001667212D0,0.09D0/
      DATA XNU,CC0,CX/15.75592D0,0.004235D0,-0.001667212D0/
      DATA C1,C2,C3,C4/0.002568D0,0.023266D0,7.389D-6,8.723D0/
      DATA C5,C6,A4/0.472D0,7.389D-2,100.0D0/
      DATA BET,BETR/0.0667263D0,14.98659D0/
      DATA DELT,DELTR/2.697586D0,0.3707018D0/
      DATA RS2R0/0.66343644D0/
      DATA THRD,THRD2/0.3333333333333333D0,0.6666666666666667D0/ 
      DATA SIXTH/0.1666666666666667D0/
      DATA THDSEV/0.4285714285714286D0/
      GR = 1.0D0/G
      G3 = G**3
      G4 = G3*G
      G3R = GR**3
      G4R = G3R*GR
      PON = -DELT*EC*G3R*BETR
      BEX = EXP(PON)-1.0D0
      B = DELT/BEX
      B2 = B*B
      T2 = T*T
      T4 = T2*T2
      T6 = T4*T2
      RS2 = RS*RS
      RS3 = RS2*RS
      Q4 = 1.0D0+B*T2
      Q5 = 1.0D0+B*T2+B2*T4
      Q6 = C1+C2*RS+C3*RS2
      Q7 = 1.0D0+C4*RS+C5*RS2+C6*RS3
      Q7R = 1.0D0/Q7
      CC = -CX + Q6*Q7R
      R0 = RS2R0*RS
      R1 = A4*R0*G4
      COEFF = CC-CC0-THDSEV*CX
      R2 = XNU*COEFF*G3
      R3 = EXP(-R1*T2)
      H0 = G3*BET*DELTR*LOG(1.0D0+DELT*Q4*T2/Q5)
      H1 = R3*R2*T2
      H = H0+H1
C
C  LOCAL CORRELATION OPTION:
C     H = 0.0D0
C
C  ENERGY DONE. NOW THE POTENTIAL:
C
C  ORIGINAL CODE DID NOT WORK FOR ZET = 1 OR ZET = -1
C  BECAUSE IN THIS CASE GZ IS NOT A NUMBER 
C  CRUDE REMEDY: NEXT LINE  
C
      IF ((1.0D0-ABS(ZET)) .LT. 1.0D-10) ZET=(1.0D0-1.0D-10)*ZET
C
      CCRS = (C2+2*C3*RS)*Q7R - Q6*(C4+2*C5*RS
     &        +3*C6*RS2)*Q7R*Q7R
      RSTHRD = RS*THRD
      R4 = RSTHRD*CCRS/COEFF
      GZ = ((1.0D0+ZET)**(-THRD) - (1.0D0-ZET)**(-THRD))*THRD
      FAC = BEX+1.0D0
      BG = -3*B2*EC*FAC*BETR*G4R 
      BEC = B2*FAC*BETR*G3R
      Q8 = Q5*Q5+DELT*Q4*Q5*T2
      Q8R = 1.0D0/Q8
      Q82R = Q8R*Q8R
      Q9 = 1.0D0+2*B*T2
      H0B = -BET*G3*B*T6*(2.0D0+B*T2)*Q8R
      H0RS = -RSTHRD*H0B*BEC*ECRS
      FACT0 = 2*DELT-6*B
      FACT1 = Q5*Q9+Q4*Q9*Q9
      H0BT = 2*BET*G3*T4*(Q4*Q5*FACT0-DELT*FACT1)*Q82R
      H0RST = RSTHRD*T2*H0BT*BEC*ECRS
      H0Z = 3*GZ*H0*GR + H0B*(BG*GZ+BEC*ECZET)
      H0T = 2*BET*G3*Q9*Q8R
      H0ZT = 3*GZ*H0T*GR+H0BT*(BG*GZ+BEC*ECZET)
      FACT2 = Q4*Q5+B*T2*(Q4*Q9+Q5)
      FACT3 = 2*B*Q5*Q9+DELT*FACT2
      H0TT = 4*BET*G3*T*(2*B*Q8R-Q9*FACT3*Q82R)
      H1RS = R3*R2*T2*(-R4+R1*T2*THRD)
      FACT4 = 2.0D0-R1*T2
      H1RST = R3*R2*T2*(2*R4*(1.0D0-R1*T2)-THRD2*R1*T2*FACT4)
      H1Z = GZ*R3*R2*T2*(3.0D0-4*R1*T2)*GR
      H1T = 2*R3*R2*(1.0D0-R1*T2)
      H1ZT = 2*GZ*R3*R2*(3.0D0-11*R1*T2+4*R1*R1*T4)*GR
      H1TT = 4*R3*R2*R1*T*(-2.0D0+R1*T2)
      HRS = H0RS+H1RS
      HRST = H0RST+H1RST
      HT = H0T+H1T
      HTT = H0TT+H1TT
      HZ = H0Z+H1Z
      HZT = H0ZT+H1ZT
      COMM = H+HRS+HRST+T2*HT*SIXTH+7*T2*T*HTT*SIXTH
      PREF = HZ-GZ*T2*HT*GR
      FACT5 = GZ*(2*HT+T*HTT)*GR
      COMM = COMM-PREF*ZET-UU*HTT-VV*HT-WW*(HZT-FACT5)
      DVCUP = COMM + PREF
      DVCDN = COMM - PREF
C
C  LOCAL CORRELATION OPTION:
C
C     DVCUP = 0.0D0
C     DVCDN = 0.0D0
      RETURN
      END
