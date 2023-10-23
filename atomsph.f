       SUBROUTINE ATOMSPH(ISTEP)
C
C ANALYZE BY MRP JULY 1998
C * CHARGES WITHIN A SPHERE
C
C ANGULAR DECOMPOSITION FOR WAVEFUNCTIONS       
C
       INCLUDE 'PARAMS'
       INCLUDE 'commons.inc'
       PARAMETER (NMAX=MPBLOCK)
       PARAMETER (LMXX=20)
       PARAMETER (LSIZ=(LMXX+1)**2)
       PARAMETER (MAXANG=((2*LMXX+1)*(LMXX+1)))
       PARAMETER (MAXSPH=500)
       PARAMETER (MAXRAD=1000)
       PARAMETER (MXCHG=56)
       PARAMETER (NAX_PTS=13000)
       CHARACTER*80 LINE
C
C FOOL THE COMPILER FOR MXSPN=1 TO SUPRESS WARNING MESSAGES
C THAT ARE REALLY IRRELEVANT
C
       LOGICAL LMKFIL,EXIST
       LOGICAL IUPDAT,ICOUNT
C
C SCRATCH COMMON BLOCK FOR LOCAL ARRAYS
C
       COMMON/TMP1/PTS(NSPEED,3),PSIL(MAX_OCC,LSIZ,2)
     &  ,RANG(3,MAXANG),QL(LMXX+2),QTOT(LMXX+2),DOS(LMXX+2)
     &  ,QLDS(LMXX+2,MAX_OCC),YLM(MAXANG,LSIZ)
     &  ,EMN(MAXSPH),EMX(MAXSPH),XRAD(MAXRAD),WTRAD(MAXRAD)
     &  ,CENTER(6,MAXSPH),ANGLE(3,MAXANG),DOMEGA(MAXANG)
     &  ,RVECA(3,MX_GRP),GRAD(NSPEED,10,6,MAX_CON,3)
     &  ,ICOUNT(MAX_CON,3)
       COMMON/TMP2/PSIG(NMAX,MAX_OCC),RHOG(NAX_PTS,10,MXSPN)
C
       DIMENSION ISIZE(3),MSITES(1),SPN(2)
       DIMENSION TENSOR(3,3,2),EIPOLE(3),EVT(3),SVT(3,3) 
       DIMENSION SCT(6)
       REAL*8 VDW(MXCHG),RKOV(MXCHG)
       CHARACTER*12 ATOMSTR 
       DATA ISIZE/1,3,6/
       DATA AU2ANG/0.529177D0/

C VDW are in Angs!!!!!
      DATA (VDW(I),I=1,MXCHG) /
     & 1.000, 1.400, 1.520, 1.113, 0.795,
     & 1.700, 1.500, 1.400, 1.400, 1.500,
     & 1.858, 1.599, 1.432, 1.176, 1.105,
     & 1.800, 1.800, 1.800, 2.272, 1.974,
     & 1.606, 1.448, 1.311, 1.249, 1.367,
     & 1.241, 1.253, 1.246, 1.278, 1.335,
     & 1.221, 1.225, 1.245, 1.160, 2.000,
     & 1.900, 2.475, 2.151, 1.776, 1.590,
     & 1.429, 1.363, 1.352, 1.325, 1.345,
     & 1.376, 1.445, 1.489, 1.626, 1.405,
     & 1.450, 1.432, 2.200, 2.100, 2.655,
     & 2.174/
C
      DATA (RKOV(I),I=1,MXCHG) /
     & 0.300, 0.000, 1.230, 0.890, 0.810,
     & 0.770, 0.700, 0.660, 0.640, 0.000,
     & 1.570, 1.360, 1.180, 1.170, 1.100,
     & 1.040, 0.990, 0.000, 2.030, 1.740,
     & 1.440, 1.320, 1.220, 1.180, 1.180,
     & 1.160, 1.160, 1.150, 1.170, 1.250,
     & 1.250, 1.220, 1.210, 1.170, 1.140,
     & 0.000, 2.160, 1.910, 1.620, 1.450,
     & 1.340, 1.300, 1.270, 1.250, 1.250,
     & 1.280, 1.340, 1.410, 1.500, 1.400,
     & 1.410, 1.370, 1.330, 0.000, 2.530,
     & 1.980/
C
C RETURN IF INPUT FILE DOES NOT EXIST
C
        PRINT '(A)','CALCULATING ATOMIC CHARGES WITHIN SHPERES'
        INQUIRE(FILE='ATOMSPH',EXIST=EXIST)
        IF (.NOT.EXIST) THEN
         PRINT '(2A)','ATOMSPH: FILE ATOMSPH DOES NOT EXIST ',
     &                '--> NOTHING TO DO'
         RETURN
        END IF
C
C CREATE A STANDARD INPUT FILE IF THE CURRENT INPUT FILE IS EMPTY 
C
        CALL GTTIME(TIME1)
        PI= 4*ATAN(1.0D0)
        LMKFIL=.TRUE.
        OPEN(74,FILE='ATOMSPH',FORM='FORMATTED',STATUS='OLD')
        OPEN(75,FILE='INERTIA',FORM='FORMATTED',STATUS='UNKNOWN')
        REWIND(74)
        REWIND(75)
        READ(74,*,END=5,ERR=5) ISWITCH
        IF (ISWITCH .NE. 0) LMKFIL=.FALSE.
    5   CLOSE(74)
C
        IF (LMKFIL) THEN
         OPEN(74,FILE='ATOMSPH',FORM='FORMATTED',STATUS='OLD')
         REWIND(74)
         WRITE(74,*) '0  auto=0, otherwise user-defined'
         WRITE(74,*) '1.0D-5 0.02 5 2  ERR,ALPMIN,LMAX,NPOW'
         WRITE(74,1010) NIDENT
 1010    FORMAT(' ',I5,' NUMBER OF CENTERS')
         DO IATOM=1,NIDENT
          DO J=1,3
           CENTER(J,IATOM)=RIDT(J,IATOM)
          END DO
          Z=ZNUC(IFUIDT(IATOM))
          CENTER(6,IATOM)=200*ABS(Z)**3
         END DO
         DO IATOM=1,NIDENT
          CENTER(4,IATOM)=0.0D0
          CENTER(5,IATOM)=50.D0
          DO JATOM=1,NIDENT
            CALL GASITES(1,CENTER(1,JATOM),MTOT,RVECA,MSITES)
            DO KATOM=1,MTOT
             DD=      SQRT((CENTER(1,IATOM)-RVECA(1,KATOM))**2+
     &                     (CENTER(2,IATOM)-RVECA(2,KATOM))**2+
     &                     (CENTER(3,IATOM)-RVECA(3,KATOM))**2)
             IF(DD.LT.0.1) DD=50.0D0
             IF (DD.LT.CENTER(5,IATOM)) CENTER(5,IATOM)=DD
            END DO
          END DO
          RR=RKOV(INT(ZNUC(IFUIDT(IATOM))))/AU2ANG
          RV=VDW(INT(ZNUC(IFUIDT(IATOM))))/AU2ANG
          IF (RR.LE.0.1D0) RR= RV
          IF (CENTER(5,IATOM).GT.RR) THEN
           CENTER(5,IATOM)=RR
          ELSE
           CENTER(5,IATOM)=CENTER(5,IATOM)*0.5D0
          ENDIF
C
          WRITE(74,1022)(CENTER(J,IATOM),J=1,6),(SYMATM(L,IATOM),L=1,10)
 1022     FORMAT(3(1X,F10.5),2(1X,F8.4),1X,E10.2,2X,10A)
         END DO
         CLOSE(74)
        END IF
C
C READ INPUT FILE
C CENTER CONTAINS THE COORDINATES (X,Y,Z), THE RADII R1,R2 AND THE
C MAXIMUM ALPHA FOR EACH CENTER
C
        OPEN(74,FILE='ATOMSPH',FORM='FORMATTED',STATUS='OLD')
        REWIND(74)
        READ(74,*,END=10) ISWITCH
        READ(74,*,END=10) ERRMAX,AMIN,LMAX,NPOW
        READ(74,*,END=10) NSPHERE
        IF (NSPHERE.GT.MAXSPH) THEN
         PRINT *,'DECOMP: MAXSPH MUST BE AT LEAST: ',NSPHERE
         GOTO 20
        END IF
        DO I=1,NSPHERE
         READ(74,33) LINE
         READ(LINE,*)(CENTER(J,I),J=1,6)
         DO J=80,1,-1
          IF (LINE(J:J).NE.' ') THEN 
           DO L=1,10
            IH=J-10+L
            SYMATM(L,I)=LINE(IH:IH)
           ENDDO
           GOTO 13
          ENDIF
         ENDDO
   13   CONTINUE 
        END DO
        GOTO 30
   10   PRINT *,'ATOMSPH: INPUT FILE IS INVALID'
   20   CLOSE(74) 
        GOTO 900
   30   CONTINUE
   33   FORMAT(A80)
C
C JK temp only : write results in extra files
        CLOSE(74)
        WRITE(ATOMSTR,'(A,I2.2)')'ATOMSPH',ISTEP
        OPEN(74,FILE=ATOMSTR,FORM='FORMATTED',STATUS='UNKNOWN')
C temp end
         WRITE(74,*)
         WRITE(74,'(A7,18X,A4,8X,A7)')'CENTER ','RMAX','CHARGES'
C
C LMAX, LMX2 CHECK AND SETUP
C
        IF (LMAX.GT.10) THEN
         LMAX=10
         PRINT '(A)','DECOMP: WARNING: LMAX HAS BEEN REDUCED TO 10'
        END IF
        LMX2=LMXX ! (2*LMAX) USUALLY OK...
C
C SETUP ANGULAR POINTS AND SPHERICAL HARMONICS
C FIRST, CHECK IF ENOUGH SPACE IN YLM
C
        MPTS=0
        IF (DEBUG) PRINT *,'MAXANG IN DECOMP: ',MAXANG
        CALL HARMONICS(MAXANG,MPTS,LMAX,ANGLE,YLM,NPOL)
        IF (NPOL.GT.LSIZ) THEN
         PRINT *,'DECOMP: LSIZ MUST BE AT LEAST: ',NPOL
         CALL STOPIT
        END IF
C
C CALL ANGMSH TO GET ANGULAR POINTS. THEN, SEND THESE POINTS TO
C HARMONICS AND GET SPHERICAL HARMONICS
C
        CALL ANGMSH(MAXANG,LMX2,NANG,ANGLE,DOMEGA)
        IF (DEBUG) PRINT *,'DECOMP-ANGMSH: LMAX,NANG: ',LMX2,NANG
C
C LOOP FOR EACH SPHERE
C START BY SETTING UP RADIAL POINTS
C
        DO 850 ISPHERE=1,NSPHERE
         CALL GASITES(1,CENTER(1,ISPHERE),MTOT,RVECA,MSITES)
         RMIN=CENTER(4,ISPHERE)
         RMAX=CENTER(5,ISPHERE)
         AMAX=CENTER(6,ISPHERE)
         AFUDGE=1.2D0
          CALL RADMSH(MAXRAD,RMIN,RMAX,ERRMAX,AMIN,AMAX,AFUDGE,NPOW,
     &                NRAD,XRAD,WTRAD)
          NMSH=NRAD*NANG
          IF (NMSH .GT. NAX_PTS) THEN
           PRINT *,'ANALYZE: NAX_PTS EXCEEDED, NMSH: ',NMSH
           PRINT *,'SKIPPING ATOM SPHERE ',ISPHERE
           GOTO 850
          END IF
         PRINT '(A,I5,A,I5,A,F15.5)','SPHERE ',ISPHERE,
     &         ': ',NRAD*NANG,' POINTS, RADIUS= ',RMAX
C
C RADIAL INTEGRALS ARE STORED IN PSIL(IWF,LM,2)
C
C CALCULATE CHARGE DENSITIES AT EACH POINT IN SPACE:
C FOR RADIAL SPHERES:
         NMSH=0
         VOL=0
         DO IR=1,NRAD
          DO IANG=1,NANG
          NMSH=NMSH+1
           RMSH(1,NMSH)=XRAD(IR)*ANGLE(1,IANG)+CENTER(1,ISPHERE)
           RMSH(2,NMSH)=XRAD(IR)*ANGLE(2,IANG)+CENTER(2,ISPHERE)
           RMSH(3,NMSH)=XRAD(IR)*ANGLE(3,IANG)+CENTER(3,ISPHERE)
           WMSH(NMSH)=WTRAD(IR)*DOMEGA(IANG)
           VOL=VOL+WMSH(NMSH)
          END DO
         END DO
          EXACT=(4.0D0/3.0D0)*PI*RMAX**3
          IF (DEBUG) PRINT *,'TOTAL NUMBER OF POINTS: ',NMSH
          IF (DEBUG) PRINT *,'TOTAL VOLUME: ',VOL,' EXACT: ',EXACT
C
           DO ISPN=1,NSPN
            DO IPTS=1,NMSH
             RHOG(IPTS,ISPN,1)=0.0D0
            END DO
           END DO
C
C POINTS LOOP
C
         LPTS=0
   40    CONTINUE
          MPTS=MIN(NMAX,NMSH-LPTS)
          LPBEG=LPTS
C
C INITIALIZE PSIG 
C
          DO IWF=1,NWF
           DO IPTS=1,MPTS
            PSIG(IPTS,IWF)=0.0D0
           END DO  
          END DO  
          ISHELLA=0
          DO 86 IFNCT=1,NFNCT
           LMX1=LSYMMAX(IFNCT)+1
           DO 84 I_POS=1,N_POS(IFNCT)
            ISHELLA=ISHELLA+1
            CALL OBINFO(1,RIDT(1,ISHELLA),RVECA,M_NUC,ISHDUMMY)
            DO 82 J_POS=1,M_NUC
             CALL UNRAVEL(IFNCT,ISHELLA,J_POS,RIDT(1,ISHELLA),
     &                    RVECA,L_NUC,1)
             IF(L_NUC.NE.M_NUC)THEN
              PRINT *,'DECOMP: PROBLEM IN UNRAVEL'
              CALL STOPIT 
             END IF
             LPTS=LPBEG
             DO 80 JPTS=1,MPTS,NSPEED
              NPV=MIN(NSPEED,MPTS-JPTS+1)
              DO LPV=1,NPV
               PTS(LPV,1)=RMSH(1,LPTS+LPV)-RVECA(1,J_POS)
               PTS(LPV,2)=RMSH(2,LPTS+LPV)-RVECA(2,J_POS)
               PTS(LPV,3)=RMSH(3,LPTS+LPV)-RVECA(3,J_POS)
              END DO
C
C GET ORBITS AND DERIVATIVES
C
              CALL GORBDRV(0,IUPDAT,ICOUNT,NPV,PTS,IFNCT,GRAD)
C
C UPDATING ARRAY PSIG
C
              IF (IUPDAT) THEN
               IPTS=JPTS-1
               ILOC=0
               DO 78 LI=1,LMX1
                DO MU=1,ISIZE(LI)
                 DO ICON=1,N_CON(LI,IFNCT)
                  ILOC=ILOC+1
                  IF (ICOUNT(ICON,LI)) THEN
                   DO IWF=1,NWF
                    FACTOR=PSI(ILOC,IWF,1)
                    DO LPV=1,NPV
                     PSIG(IPTS+LPV,IWF)=PSIG(IPTS+LPV,IWF)
     &               +FACTOR*GRAD(LPV,1,MU,ICON,LI)
                    END DO
                   END DO  
                  END IF
                 END DO  
                END DO  
   78          CONTINUE
              END IF
              LPTS=LPTS+NPV
   80        CONTINUE
   82       CONTINUE
   84      CONTINUE
   86     CONTINUE
C
C UPDATE CHARGE DENSITY:
C
           IWF=0
           DO ISPN=1,NSPN
           DO JWF=1,NWFS(ISPN)
           IWF=IWF+1
            DO IPTS=1,MPTS
             RHOG(IPTS+LPBEG,ISPN,1)=
     &       RHOG(IPTS+LPBEG,ISPN,1)+PSIG(IPTS,IWF)**2
            END DO
           END DO
           END DO
C
C CHECK IF ALL POINTS DONE
C
          LPTS=LPBEG+MPTS
          IF(LPTS.GT.NAX_PTS)THEN
           PRINT *,'DECOMP: ERROR: LPTS >',NAX_PTS
           CALL STOPIT
          ELSE
           IF(LPTS.LT.NMSH) GOTO 40
          END IF
  500    CONTINUE
C ANALYSE SPIN DENSITIES:
CCCCCCCCCCCCCCCCCCCCC UNDERSTAND THIS PART CCCCCCCCCCCCCCCCCCCCCCCCCCC
          SPN=0.0D0
          TENSOR=0.0D0
          EIPOLE=0.0D0
          DO ISPN=1,NSPN
C integral(inside sphere) spin_density
C calculate moment of intertia Ixy=Integral(sphere) xy rho(r_vec) d^3r
C
          DO IPTS=1,NMSH
           SPN(ISPN)=SPN(ISPN)+RHOG(IPTS,ISPN,1)*WMSH(IPTS)
           DO IX=1,3
           EIPOLE(IX)        =EIPOLE(IX)+RHOG(IPTS,ISPN,1)
     &                 *(RMSH(IX,IPTS)-CENTER(IX,ISPHERE))*WMSH(IPTS)
           DO IY=1,3
           TENSOR(IX,IY,ISPN)=TENSOR(IX,IY,ISPN)+RHOG(IPTS,ISPN,1)
     &                 *(RMSH(IX,IPTS)-CENTER(IX,ISPHERE))
     &                 *(RMSH(IY,IPTS)-CENTER(IY,ISPHERE))*WMSH(IPTS)
           END DO
           END DO
          END DO
          END DO
          DNS=SPN(1)+SPN(NSPN)
          RMN=SPN(NSPN)-SPN(1) 
          SPN(1)=DNS
          SPN(2)=RMN
          WRITE(75,100)ISPHERE,(SYMATM(L,ISPHERE),L=1,10),
     &               CENTER(5,ISPHERE)!,(SPN(ISPN),ISPN=1,NSPN)
          WRITE(75,*)'Local Dipole Moment:'
          WRITE(75,75) (EIPOLE(IX        ),IX=1,3)        
          DO ISPN=1,NSPN
          WRITE(75,*)'CHARGE DENSITY TENSOR FOR:',ISPN
          WRITE(75,75)((TENSOR(IX,IY,ISPN),IX=1,3),IY=1,3)
                          SVT=0.0D0
                          DO I=1,3
                          SVT(I,I)=1.0D0
                          END DO 
          CALL DIAGGE(3,3,TENSOR(1,1,ISPN),SVT,EVT,SCT,1)
          WRITE(75,*)'Eigenvalues and Principal Axes for Spin:',ISPN
          WRITE(75,75)(EVT(I),I=1,3)
          WRITE(75,*)
          WRITE(75,75)((TENSOR(J,I,ISPN),J=1,3),I=1,3)
 75       FORMAT(3F12.6)
          END DO
          WRITE(74,100)ISPHERE,(SYMATM(L,ISPHERE),L=1,10),
     &               CENTER(5,ISPHERE),(SPN(ISPN),ISPN=1,NSPN)
CCCCCCCCCCCCCCCCC END OF PART THAT NEEDS TO BE UNDERSTOOD CCCCCCCCCCC
 100      FORMAT(I4,2X,10A,2X,3F12.4) 
 102      FORMAT(' CHARGES: ',2X,I4,2X,10A,2X,3F12.4) 
  850   CONTINUE
        CLOSE(74)
  900   CONTINUE
         CLOSE(75)
C REREAD MESH... (ATOMSPH OVERWROTE IT...)
          OPEN(99,FILE='VMOLD',FORM='UNFORMATTED',STATUS='UNKNOWN')
          READ(99)NMSH,MCALC
          READ(99)((RMSH(J,I),J=1,3),I=1,NMSH)
          READ(99)(WMSH(I),I=1,NMSH)
          CLOSE(99)
C END OF REREADING                       
        CALL GTTIME(TIME2)
        CALL TIMOUT('CHARGES IN ATOMIC SPHERES:         ',TIME2-TIME1)
        RETURN
       END
