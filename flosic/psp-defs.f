      FUNCTION IPSCHG(NAMPSP,IZNUC)
C
C DEFINES THE VALENCE CHARGE FOR PSEUDOPOTENTIAL CALCULATIONS
C
       INCLUDE 'PARAMS'
       INCLUDE 'commons.inc'
       PARAMETER (MXZBHS=94)
       CHARACTER*3 NAMPSP
       DIMENSION NZVBHS(MXZBHS)
       DATA (NZVBHS(I),I=1,MXZBHS)/
     &       1,2,
     &       1,2,3,4,5,6,7,8,
     &       1,2,3,4,5,6,7,8,
     &       1,2,3,4,5,6,7,8,9,10,11,12,3,4,5,6,7,8,
     &       1,2,3,4,5,6,7,8,9,10,11,12,3,4,5,6,7,8,
     &       1,2,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,
     &         4,5,6,7,8,9,10,11,12,3,4,5,6,7,8,
     &       1,2,3,4,5,6,7,8/
       IF (IZNUC .LE. 0) THEN
        IPSCHG=0
        RETURN
       END IF
       IF (NAMPSP .EQ. 'ALL') THEN
        IPSCHG=IZNUC
       ELSE IF (NAMPSP .EQ. 'BHS') THEN
        IF (IZNUC .LE. MXZBHS) THEN
         IPSCHG=NZVBHS(IZNUC)
        ELSE
         PRINT *,'IPSCHG: BHS PSP NOT DEFINED FOR Z= ',IZNUC
         CALL STOPIT
        END IF
       ELSE
        PRINT *,'IPSCHG: UNKNOWN PSP TYPE: ',NAMPSP,IZNUC
        CALL STOPIT
       END IF
        PRINT *,'IPSCHG: UNKNOWN PSP TYPE: ',NAMPSP,IZNUC
       RETURN
      END 
C
C *******************************************************************
C
      SUBROUTINE SETBAS(IZNUC,NAMPSP,ALP,CON,NALP,NBASF)
C
C DIRK POREZAG, AUGUST 1997
C SETUP BASIS SET DEPENDING ON NUCLEAR CHARGE AND PSP
C
       INCLUDE 'PARAMS'
       INCLUDE 'commons.inc'
       CHARACTER*3 NAMPSP
       DIMENSION ALP(MAX_BARE),CON(MAX_BARE,MAX_CON,3),NBASF(2,3)
C
       IF (NAMPSP .EQ. 'ALL') THEN
        CALL SALLBAS(IZNUC,ALP,CON,NALP,NBASF)
       ELSE IF (NAMPSP .EQ. 'BHS') THEN
        CALL SBHSBAS(IZNUC,ALP,CON,NALP,NBASF)
       ELSE
        PRINT *,'SETBAS: PSEUDOPOTENTIAL TYPE ',NAMPSP,' IS ',
     &          'NOT RECOGNIZED'
        CALL STOPIT
       END IF
       RETURN
      END
C
C *******************************************************************
C
      SUBROUTINE SETPSP(IUNIT,SYMPSP,IZNUC)
C
C DIRK POREZAG, AUGUST 1997
C SETUP PSEUDOPOTENTIAL (PSP) DATA 
C
       INCLUDE 'PARAMS'
       INCLUDE 'commons.inc'
       CHARACTER*7 SYMPSP
       CHARACTER*3 NAMPSP
C
       NAMPSP=SYMPSP(1:3)
       IF (NAMPSP .EQ. 'ALL') RETURN
       IF (NAMPSP .EQ. 'BHS') THEN
        CALL SBHSPSP(IUNIT,SYMPSP,IZNUC)
       ELSE
        PRINT *,'SETPSP: PSEUDOPOTENTIAL TYPE ',NAMPSP,' IS ',
     &          'NOT RECOGNIZED'
        CALL STOPIT
       END IF
       WRITE(IUNIT,'(A3)') '***'
       RETURN
      END
C
C *******************************************************************
C
      BLOCK DATA PSPSTUFF
       INCLUDE 'PARAMS'
       INCLUDE 'commons.inc'
       DATA PSRZONE/0.2D0, 0.4D0, 0.8D0, 1.6D0/
       DATA LMXPSRZ/7, 9, 11, 13, 15/
      END
C
C ****************************************************************
C
      SUBROUTINE READPSP
C
C DIRK POREZAG, JULY 1997
C READ PSEUDOPOTENTIAL PARAMETERS, SET UP RADIAL MESH AND NONLOCAL
C PART OF PSEUDOPOTENTIAL
C COMMON/PSPANG/ CONTAINS THE ANGULAR DEGREE OF THE MESH
C USED FOR THE INTEGRATION OF THE NONLOCAL PSEUDOPOTENTIAL 
C
       INCLUDE 'PARAMS'
       INCLUDE 'commons.inc'
       LOGICAL EXIST,LNLCC
       CHARACTER*7 SYM1
       CHARACTER*3 SYM2,SYM3
       COMMON/TMP1/RRAD(MXRPSP),WRAD(MXRPSP),VNRAD(MXLPSP+1,MXRPSP)
     &  ,VLRAD(2,MXRPSP)
     &  ,BHS1(2),BHS2(2),BHS3(3,MXLPSP+1),BHS4(6,MXLPSP+1)
     &  ,BHSMAT(6,6),BHSDRC(6),BHSSAV(6)
     &  ,RREAD(MXPTAB),VREAD(MXPTAB,MXLPSP+2),RHCREAD(MXPTAB)
     &  ,ISDEF(MAX_FUSET),ITABLE(MAX_FUSET)
       DATA PSPMERR/1.0D-6/
       DATA AFUDGE /1.2D+0/
       DATA NPOWPSP/     6/
C
C INITIALIZE ARRAYS IN COMMON BLOCKS
C
       DO IFNCT= 1,NFNCT
        BHSALP(1,IFNCT)= 1.0D0
        BHSALP(2,IFNCT)= 1.0D0
        BHSCOF(1,IFNCT)= 0.0D0
        BHSCOF(2,IFNCT)= 0.0D0
        NRADTAB(IFNCT)= 0
        NLCC(IFNCT)= 0
        LMAXNLO(IFNCT)= -1
        NRPSP(IFNCT)= 0
       END DO
       IF (ISITPSP .NE. 1) RETURN
C
C DEAL WITH MESH FIRST
C
       PRINT '(A)','READING PSEUDOPOTENTIAL DATA'
       INQUIRE(FILE='MESHPSP',EXIST=EXIST)
       IF (EXIST) THEN
        OPEN(50,FILE='MESHPSP',FORM='FORMATTED',STATUS='OLD')
        REWIND(50)
        READ(50,*,END=20) PSPMERR,AFUDGE,NPOWPSP
        READ(50,*,END=20)(PSRZONE(I), I=1,4)
        READ(50,*,END=20)(LMXPSRZ(I), I=1,5)
       END IF
       CLOSE(50)
       GOTO 40
C
C ERROR
C
   20  PRINT *,'READPSP: FILE MESHPSP IS BROKEN'
       CLOSE(50)
       CALL STOPIT
C
C WRITE MESHPSP
C
   40  OPEN(50,FILE='MESHPSP',FORM='FORMATTED',STATUS='UNKNOWN')
       REWIND(50)
       WRITE(50,1010) PSPMERR,AFUDGE,NPOWPSP,
     &                ' Accuracy, Afudge, Max. power'
       WRITE(50,1020)(PSRZONE(I), I=1,4),' Radial zones'
       WRITE(50,1030)(LMXPSRZ(I), I=1,5),' Max. L for each zone'
 1010  FORMAT(2(1X,D15.8),1X,I3,4X,A)
 1020  FORMAT(4(1X,F8.3),4X,A)
 1030  FORMAT(5(1X,I3),20X,A)
       CLOSE(50)
C
C SET ISDEF TO 0 FOR ALL PSP-ATOMS
C
       DO IFNCT=1,NFNCT
        IF (PSPSYM(IFNCT)(1:3) .EQ. 'ALL') THEN
         ISDEF(IFNCT)= 1
        ELSE
         ISDEF(IFNCT)= 0
        END IF
       END DO
C
C NOW READ THE ACTUAL PSEUDOPOTENTIALS FROM PSPINP
C
       INQUIRE(FILE='PSPINP',EXIST=EXIST)
       IF (.NOT. EXIST) GOTO 950
       OPEN(40,FILE='PSPRAD',FORM='FORMATTED',STATUS='UNKNOWN')
       OPEN(50,FILE='PSPINP',FORM='FORMATTED',STATUS='OLD')
       REWIND(40)
       REWIND(50)
C
C READ UNTIL END OF FILE
C
  110  READ(50,'(A7)',END=500) SYM1
       SYM2=SYM1(1:3)
       READ(50,*,END=900) LMAX
       IF (LMAX .GT. MXLPSP) THEN
        PRINT *,'READPSP: MXLPSP MUST BE AT LEAST: ',LMAX
        GOTO 950
       END IF
C
C PSP-DEPENDENT INPUT FROM PSPINP
C
C TYPE BHS: BACHELET-HAMANN-SCHLUTER, SEE:
C PRB 26, 4199 (ERRATA: PRB 29, 2309) 
C
       IF (SYM2 .EQ. 'BHS') THEN
        LNLCC= .FALSE.
        READ(50,*,END=900)(BHS1(I), I=1,2)      ! Core Alphas
        READ(50,*,END=900)(BHS2(I), I=1,2)      ! Core Coefficients
        PI=4*ATAN(1.0D0)
        DO L1=1,LMAX+1
         READ(50,*,END=900)(BHS3(I,L1), I=1,3)  ! NL Alphas
         READ(50,*,END=900)(BHS4(I,L1), I=1,6)  ! NL Coefficients 
C
C TRANSFORMATION OF BHS COEFFICIENTS TO "SIMPLE" COEFFICIENTS
C FILL BHSMAT WITH "OVERLAP" MATRIX ELEMENTS AS DEFINED IN BHS PAPER
C
         DO IALP=1,3
          DO JALP=IALP,3
           FAC= 1.0D0/(BHS3(IALP,L1)+BHS3(JALP,L1))
           BHSMAT(IALP,JALP)= 0.25D0*FAC*SQRT(PI*FAC)
           BHSMAT(IALP,JALP+3)= BHSMAT(IALP,JALP)*1.5D0*FAC
           BHSMAT(IALP+3,JALP+3)= BHSMAT(IALP,JALP+3)*2.5D0*FAC
          END DO
         END DO
         BHSMAT(2,4)=BHSMAT(1,5)
         BHSMAT(3,4)=BHSMAT(1,6)
         BHSMAT(3,5)=BHSMAT(2,6)
C
C UPDATE BHSMAT (CORRESPONDS TO MATRIX Q IN BHS PAPER)
C
         DO I=1,6
          DO J=I,6
           SUM=BHSMAT(I,J)
           DO K=1,I-1
            SUM= SUM-BHSMAT(K,I)*BHSMAT(K,J)
           END DO
           IF (I .EQ. J) THEN
            IF (SUM .LE. 0.0D0) THEN
             PRINT *,'READPSP: BHS TRANSFORMATION ERROR'
             CALL STOPIT
            END IF
            BHSMAT(I,I)= SQRT(SUM)
            BHSDRC(I)= 1.0D0/BHSMAT(I,I)
           ELSE
            BHSMAT(I,J)= SUM*BHSDRC(I)
           END IF
          END DO
         END DO
C
C SYMMETRIZE BHSMAT AND MOVE DATA FROM BHS4 TO BHSSAV
C
         DO I= 1,6
          BHSSAV(I)= -BHS4(I,L1)
          DO J=I+1,6
           BHSMAT(J,I)=BHSMAT(I,J)
          END DO
         END DO
C
C BACKWARD SUBSTITUTION
C
         DO I= 6, 1, -1
          BHS4(I,L1)= BHSSAV(I)
          DO J= I+1,6
           BHS4(I,L1)= BHS4(I,L1)-BHSMAT(J,I)*BHS4(J,L1)
          END DO
          BHS4(I,L1)= BHS4(I,L1)*BHSDRC(I)
         END DO
C
C CHECK CONDITION OF THE PROBLEM
C
         CMAX= 0.0D0
         SUM= 0.0D0
         DO I=1,6
          FAC= 0.0D0
          DO J=I,6
           FAC= FAC+BHSMAT(J,I)*BHS4(J,L1)
          END DO
          SUM= SUM+(FAC-BHSSAV(I))**2 
          CMAX= MAX(CMAX,ABS(BHS4(I,L1)))
         END DO
         IF (L1 .EQ. 1) THEN
          PRINT '(2A)','BHS TRANSFORMATION FOR PSEUDOPOTENTIAL ',SYM1
         END IF
         PRINT 1110,L1-1,SQRT(SUM),CMAX
 1110    FORMAT('L= ',I2,', |AX-B|= ',D12.5,
     &          ', LARGEST COEFFICIENT= ',D12.5)
        END DO
        PAMIN=  1.0D30
        PAMAX= -1.0D30
        DO L1=1,LMAX+1
         DO I=1,3
          PAMIN=MIN(PAMIN,BHS3(I,L1))
          PAMAX=MAX(PAMAX,BHS3(I,L1))
         END DO
        END DO
C 
C TYPE TAB: GENERAL TABLE OF NONLOCAL PSEUDOPOTENTIAL. FORMAT:
C MTAB,PAMIN,PAMAX= NUMBER OF TABULATED POINTS, MIN/MAX ALPHA FOR MESH,
C NONLINEAR CORE CORRECTION (T/F)
C RRADTAB,VLOTAB= RADIUS, LOCAL POTENTIAL, VNLTAB= NONOCAL POTENTIAL 
C (L= 0 TO LMAX), RHOCORE= CORE DENSITY (FOR NLCC) | NRADTAB BLOCKS
C 
       ELSE IF (SYM2 .EQ. 'TAB') THEN
        READ(50,*,END=900) MTAB,PAMIN,PAMAX,LNLCC
        NRHOC=0
        IF (LNLCC) NRHOC=1
        IF (LNLCC) ISNLCC=1
        IF (MTAB .GT. MXPTAB) THEN
         PRINT *,'READPSP: MXPTAB MUST BE AT LEAST: ',MTAB
         CALL STOPIT
        END IF
        DO ITAB=1,MTAB
         READ(50,*,END=900) RREAD(ITAB),(VREAD(ITAB,L1), L1=1,LMAX+2),
     &                     (RHCREAD(ITAB), I=1,NRHOC)
        END DO
        DO L1=1,LMAX+2
         DO ITAB=1,MTAB
          VREAD(ITAB,L1)= VREAD(ITAB,L1)*RREAD(ITAB)
         END DO
         IF (L1 .GT. 1) THEN
          DO ITAB=1,MTAB
           VREAD(ITAB,L1)= VREAD(ITAB,L1)-VREAD(ITAB,1)
          END DO
         END IF
        END DO
C
C END OF READ 
C
       ELSE
        PRINT *,'READPSP: PSEUDOPOTENTIAL TYPE ',SYM2,' IS NOT',
     &          'RECOGNIZED'
        GOTO 900
       END IF
       READ(50,'(A3)',END=900) SYM3
       IF (SYM3 .NE. '***') GOTO 900
C
C END OF PSP-DEPENDENT INPUT FROM PSPINP
C
C DETERMINE WHICH FUNCTION SETS USE THIS PSP AND FIND THEIR 
C LARGEST AND SMALLEST WAVEFUNCTION EXPONENT 
C
       NSETS=0
       WAMIN=  1.0D30
       WAMAX= -1.0D30
       DO IFNCT=1,NFNCT
        IF (PSPSYM(IFNCT) .EQ. SYM1) THEN
         NSETS=NSETS+1
         ITABLE(NSETS)=IFNCT
         DO IBARE=1,N_BARE(IFNCT)
          WAMIN=MIN(WAMIN,BFALP(IBARE,IFNCT))
          WAMAX=MAX(WAMAX,BFALP(IBARE,IFNCT))
         END DO
        END IF
       END DO
       IF (NSETS .EQ. 0) GOTO 110
C
C PRINT STATISTICS
C
       PRINT '(5A)','PSEUDOPOTENTIAL ',SYM1,' (TYPE ',SYM2,
     &              ') HAS BEEN SUCCESSFULLY PROCESSED'
C
C PSP-DEPENDENT ASSIGNMENT OF LOCAL POTENTIAL PARAMETERS
C AND CORE DENSITIES
C
       DO 200 ISET=1,NSETS
        IDX=ITABLE(ISET)
        NLCC(IDX)= 0
        IF (LNLCC) NLCC(IDX)= 1
C
C TYPE BHS
C
        IF (SYM2 .EQ. 'BHS') THEN
         DO I=1,2
          BHSALP(I,IDX)=SQRT(BHS1(I))
          BHSCOF(I,IDX)=BHS2(I)
         END DO
C
C TYPE TAB
C
        ELSE IF (SYM2 .EQ. 'TAB') THEN
         NRADTAB(IDX)=MTAB
         CALL TABDRV(10,1,0.1D0,MTAB,RREAD,VREAD,2,VLRTAB(1,1,IDX))
         IF (LNLCC) THEN 
          CALL TABDRV(10,2,0.1D0,MTAB,RREAD,RHCREAD,3,RHOCOR(1,1,IDX))
          DO I=1,MTAB
           IF (RREAD(I) .GT. 1.0D-3) GOTO 190
          END DO
  190     I=MIN(I,MTAB)
          ALPCOR(IDX)= -RHOCOR(2,I,IDX)/(2*RREAD(I)*RHOCOR(1,I,IDX))
          PRINT 1210,'ESTIMATED CORE DENSITY EXPONENT FOR SET ',IDX,
     &               ' IS: ',ALPCOR(IDX)
 1210     FORMAT(A,I3,A,F12.3)
         END IF
         DO ITAB=1,MTAB
          RRADTAB(ITAB,IDX)=RREAD(ITAB)
         END DO
        END IF
  200  CONTINUE
C
C PSP-DEPENDENT SETUP OF NONLOCAL RADIAL POTENTIAL
C
       AMIN=PAMIN
       AMAX=PAMAX+2*WAMAX
       NPOW=NPOWPSP+2 
       RMAX= RCUTOFF(NPOW,AMIN,0.1D0*PSPMERR)
       CALL RADMSH(MXRPSP,0.0D0,RMAX,PSPMERR,AMIN,AMAX,AFUDGE,NPOW,
     &             NRAD,RRAD,WRAD)
C
C TYP 1: BHS
C
       IF (SYM2 .EQ. 'BHS') THEN
        DO IRAD=1,NRAD
         RSQR=RRAD(IRAD)**2
         DO L1=1,LMAX+1
          VNRAD(L1,IRAD)=0.0D0
          DO I=1,3
           VNRAD(L1,IRAD)=VNRAD(L1,IRAD)
     &     +(BHS4(I,L1)+RSQR*BHS4(I+3,L1))*EXP(-BHS3(I,L1)*RSQR)
          END DO
         END DO
        END DO
C
C TYP 2: TAB
C
       ELSE IF (SYM2 .EQ. 'TAB') THEN
        DO IRAD=1,NRAD
         DO L1=1,LMAX+1
          CALL FINTPOL(8,1,RRAD(IRAD),0.1D0,MTAB,1,1,RREAD,
     &                 VREAD(1,L1+1),VNRAD(L1,IRAD))
          VNRAD(L1,IRAD)= VNRAD(L1,IRAD)/RRAD(IRAD)
         END DO
        END DO
       END IF
C
C PRINT RADIAL TABLE TO FILE PSPRAD
C
       WRITE(40,*) 'PSP ',SYM1,', TYPE ',SYM2
       WRITE(40,*) NRAD,LMAX,' NRAD,LMAX'
       DO IRAD=1,NRAD
        WRITE(40,1310) RRAD(IRAD),WRAD(IRAD)
        WRITE(40,1310)(VNRAD(L1,IRAD), L1=1,LMAX+1)
       END DO
 1310  FORMAT(3(1X,D20.10))
C
C ASSIGN NONLOCAL PSEUDOPOTENTIAL TO FUNCTION SETS
C
       DO ISET=1,NSETS
        IDX=ITABLE(ISET)
        ISDEF(IDX)=1
        LMAXNLO(IDX)=LMAX
        NRPSP(IDX)=NRAD
        DO IRAD=1,NRAD
         RPSNLO(IRAD,IDX)=RRAD(IRAD)
         WPSNLO(IRAD,IDX)=WRAD(IRAD)
         DO L1=1,LMAX+1
          VPSNLO(L1,IRAD,IDX)=VNRAD(L1,IRAD)
         END DO
         DO L1=LMAX+2,MXLPSP+1
          VPSNLO(L1,IRAD,IDX)=0.0D0
         END DO
        END DO
       END DO
       GOTO 110
C
  500  CLOSE(40)
       CLOSE(50)
C
C CHECK FOR UNDEFINED PSP'S  
C
       NSETS=0
       DO IFNCT=1,NFNCT
        IF (ISDEF(IFNCT) .EQ. 0) THEN
         NSETS=NSETS+1
         ITABLE(NSETS)=IFNCT
        END IF
       END DO
       IF (NSETS .EQ. 0) RETURN
       PRINT *,'READPSP: THE FOLLOWING PSEUDOPOTENTIALS ',
     &         'ARE UNDEFINED: '
       PRINT 1410,(PSPSYM(ITABLE(ISET)), ISET=1,NSETS)
 1410  FORMAT(10(1X,A7))
       CALL STOPIT
C
C READ ERROR
C
  900  CLOSE(40)
       CLOSE(50)
  950  PRINT *,'READPSP: FILE PSPINP IS MISSING OR BROKEN'
       CALL STOPIT
      END
C
C *******************************************************************
C
       SUBROUTINE VLOCAL(MODE,NPV,IFU,RDIS,VLOC)
C
C CALLED FROM APOTNL
C MODE=1: DETERMINE THE LOCAL PART OF THE NUCLEAR PSEUDOPOTENTIAL
C MODE=2: DETERMINE THE DERIVATIVE OF THE LOCAL PART OF THE NUCLEAR 
C         PSEUDOPOTENTIAL VERSUS THE DISTANCE, DEVIDED BY THE DISTANCE
C
        INCLUDE 'PARAMS'
        INCLUDE 'commons.inc'
        PARAMETER(RTPIRC=0.56418958354775628695D0)
        PARAMETER(MXITER=100)
        DIMENSION RDIS(NSPEED),VLOC(NSPEED)
        DIMENSION RDRC(NSPEED),VDRV(2,NSPEED)
        DATA ACCUM/1.0D-14/
C
C ALL-ELECTRON
C
        IF (NPV .GT. NSPEED) THEN
         PRINT *,'VLOCAL: NSPEED MUST BE AT LEAST: ',NPV
         CALL STOPIT
        END IF
        IF ((MODE .NE. 1) .AND. (MODE .NE. 2)) THEN
         PRINT *,'VLOCAL: INVALID MODE'
         CALL STOPIT
        END IF
        DO IPV=1,NPV
         RDRC(IPV)= 1.0D0/RDIS(IPV)
        END DO
        IF (PSPSYM(IFU)(1:3) .EQ. 'ALL') THEN
         IF (MODE .EQ. 1) THEN
          DO IPV=1,NPV
           VLOC(IPV)= -ZELC(IFU)*RDRC(IPV)
          END DO
         ELSE 
          DO IPV=1,NPV
           VLOC(IPV)= +ZELC(IFU)*RDRC(IPV)*RDRC(IPV)*RDRC(IPV)
          END DO
         END IF
C
C BHS
C USE OWN ERROR FUNCTION SINCE NOT F77 STANDARD
C TAYLOR EXPANSION FOR SMALL ARGUMENTS, CONTINUED FRACTION FOR LARGE ONES
C
        ELSE IF (PSPSYM(IFU)(1:3) .EQ. 'BHS') THEN
         DO 30 IPV=1,NPV
          R= RDIS(IPV)
          VLOC(IPV)= 0.0D0
          DO IALP=1,2
           X= BHSALP(IALP,IFU)*R
           X2=X*X
           IF (X2 .LE. 4.0D0) THEN
            FAC= 2*RTPIRC*EXP(-X2)
            SUM= 0.0D0
            DO I=1,MXITER
             OLD= SUM
             SUM= SUM+FAC
             IF (SUM .EQ. OLD) GOTO 10
             FAC= FAC*X2/(0.5D0+I) 
            END DO  
            PRINT *,'VLOCAL: BHS ERROR(1): X2= ',X2
            CALL STOPIT
   10       CONTINUE
            SUM= SUM*X
           ELSE 
            GOLD= 0.0D0
            A0= 1.0D0
            B0= 0.0D0
            A1= X2 
            B1= 1.0D0
            FAC= 1.0D0
            DO I=1,MXITER
             AI=I
             AIA=AI-0.5D0
             A0=(A1+A0*AIA)*FAC
             B0=(B1+B0*AIA)*FAC
             AIF=AI*FAC
             A1= X2*A0+AIF*A1
             B1= X2*B0+AIF*B1
             IF (A1 .NE. 0.0D0) THEN
              FAC= 1.0D0/A1
              G= B1*FAC
              IF (ABS(G-GOLD) .LE. ACCUM*ABS(GOLD)) GOTO 20
              GOLD=G
             END IF
            END DO 
            PRINT *,'VLOCAL: BHS ERROR(2): X2= ',X2
            CALL STOPIT
   20       CONTINUE
            SUM= 1.0D0-RTPIRC*X*EXP(-X2)*G
           END IF
           VLOC(IPV)= VLOC(IPV)+BHSCOF(IALP,IFU)*SUM
          END DO
          IF (MODE .EQ. 1) THEN
           VLOC(IPV)= -ZELC(IFU)*VLOC(IPV)*RDRC(IPV)
          ELSE
           RRC= RDRC(IPV)
           VLOC(IPV)= ZELC(IFU)*RRC*RRC*(VLOC(IPV)*RRC-2*RTPIRC
     &     *(BHSCOF(1,IFU)*BHSALP(1,IFU)*EXP(-(BHSALP(1,IFU)*R)**2)
     &      +BHSCOF(2,IFU)*BHSALP(2,IFU)*EXP(-(BHSALP(2,IFU)*R)**2)))
          END IF
   30    CONTINUE
C
C TAB
C
        ELSE IF (PSPSYM(IFU)(1:3) .EQ. 'TAB') THEN
         IF (MODE .EQ. 1) THEN
          CALL FINTPOL(8,NPV,RDIS,0.1D0,NRADTAB(IFU),2,1,RRADTAB(1,IFU),
     &                 VLRTAB(1,1,IFU),VDRV)
          DO IPV=1,NPV
           VLOC(IPV)= VDRV(1,IPV)*RDRC(IPV)
          END DO
         ELSE
          CALL FINTPOL(8,NPV,RDIS,0.1D0,NRADTAB(IFU),2,2,RRADTAB(1,IFU),
     &                 VLRTAB(1,1,IFU),VDRV)
          DO IPV=1,NPV
           VLOC(IPV)= (VDRV(2,IPV)-VDRV(1,IPV)*RDRC(IPV))*RDRC(IPV)**2
          END DO
         END IF
        END IF
        RETURN
       END
