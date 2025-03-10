SELECT  MES_ANO,
        PAC_INT_00H,
		ENT_INTERNADOS,
        ENT_TRANSF,
		SAI_ALTAS,
		SAI_TRANSFPARA,
		SAI_OBITOS,
		ROUND(PAC_DIA/30)PAC_DIA,
		TX_OCU || '%' TX_OCU,
		TX_OCU TX_OCU2,
		SAIDAS,
		CASE
		    WHEN SAIDAS = 0 
			     THEN ROUND(PAC_DIA/(SAIDAS+1),2)
		    ELSE ROUND(PAC_DIA/SAIDAS,2)
		END  MED_PER,
		100 - TX_OCU || '%' TX_OCI,		
		100 - TX_OCU TX_OCI2
		
FROM    (		
SELECT  MES_ANO,
        SUM(PAC_INT_00H) PAC_INT_00H,
		SUM(ENT_INTERNADOS) ENT_INTERNADOS,
		SUM(ENT_TRANSF) ENT_TRANSF,
		SUM(SAI_ALTAS) SAI_ALTAS,
		SUM(SAI_TRANSFPARA) SAI_TRANSFPARA,
		SUM(SAI_OBITOS) SAI_OBITOS,
		((SUM(SAI_ALTAS)+SUM(SAI_OBITOS)+SUM(SAI_TRANSFPARA))) SAIDAS,
		((SUM(PAC_INT_00H)+SUM(ENT_INTERNADOS)+SUM(ENT_TRANSF))-(SUM(SAI_ALTAS)+SUM(SAI_TRANSFPARA)+SUM(SAI_OBITOS))) PAC_DIA,
		ROUND(((((SUM(PAC_INT_00H)+SUM(ENT_INTERNADOS)+SUM(ENT_TRANSF))-(SUM(SAI_ALTAS)+SUM(SAI_TRANSFPARA)+SUM(SAI_OBITOS)))*100)/(/*Leitos por dia no periodo*/
																																	SELECT  COUNT (*) TOTALLEITO
																																	       
																																	  FROM DBAMV.LEITO,
																																		   DBAMV.UNID_INT,
																																		   DBAMV.SETOR,
																																		   DBAMV.TIP_ACOM,
																																		   (SELECT ((@p_datai) - 1) + ROWNUM DATA
																																			  FROM DBAMV.CID
																																			 WHERE ((@p_datai) - 1) + ROWNUM <=                                               (@p_dataf)) CONTADOR
																																	 WHERE CONTADOR.DATA >= LEITO.DT_ATIVACAO
																																	   AND CONTADOR.DATA <= NVL (LEITO.DT_DESATIVACAO, SYSDATE)
																																	   AND LEITO.SN_EXTRA = 'N'
																																	   AND LEITO.CD_UNID_INT = UNID_INT.CD_UNID_INT
																																	   AND UNID_INT.CD_SETOR = SETOR.CD_SETOR
																																	   AND SETOR.CD_MULTI_EMPRESA = 1
																																	   AND TIP_ACOM.CD_TIP_ACOM = LEITO.CD_TIP_ACOM
																																	   AND TIP_ACOM.TP_ACOMODACAO <> 'B'
																																	   AND UNID_INT.SN_HOSPITAL_DIA = 'N'
																																	   AND LEITO.SN_EXTRA = 'N'
																																	   AND UNID_INT.CD_UNID_INT IN ('2', '11')
																																	   AND UNID_INT.TP_UNID_INT = 'I'
																																	   AND NVL (UNID_INT.SN_HOSPITAL_DIA, 'N') = 'N'  )),2)TX_OCU
																																	           
																																	   
		
FROM    (
/*Pacientes internados até 0:00h*/
SELECT  TO_CHAR(CONTADOR.DATA,'MM/YYYY')MES_ANO,
        COUNT(*)              PAC_INT_00H,
		0 ENT_INTERNADOS,
		0 ENT_TRANSF,
		0 SAI_ALTAS,
		0 SAI_TRANSFPARA,
		0 SAI_OBITOS,
		0 TOTALLEITO
		
FROM    DBAMV.MOV_INT,
        DBAMV.UNID_INT,
        DBAMV.LEITO,
        DBAMV.ATENDIME,
        ( SELECT( (@p_datai) - 1  + ROWNUM )DATA
          FROM DBAMV.CID
          WHERE (@p_datai) - 1  + ROWNUM <= (@p_dataf)
		) CONTADOR

WHERE   TRUNC(DT_MOV_INT) <= CONTADOR.DATA - 1
  AND   TRUNC(NVL(DT_LIB_MOV, SYSDATE) ) > CONTADOR.DATA - 1
  AND   TP_MOV IN('O', 'I')
  AND   LEITO.CD_UNID_INT = UNID_INT.CD_UNID_INT
  AND   MOV_INT.CD_ATENDIMENTO = ATENDIME.CD_ATENDIMENTO
  AND   MOV_INT.CD_LEITO = LEITO.CD_LEITO
  AND   NVL(DBAMV.F_VALIDA_DATA_HOSPITAL_DIA('N',ATENDIME.DT_ALTA),'N') = 'S'
  AND   ATENDIME.TP_ATENDIMENTO  = 'I'
  AND   ATENDIME.CD_ATENDIMENTO_PAI IS NULL
  AND   UNID_INT.CD_UNID_INT IN (2,11,26)
  AND   LEITO.CD_TIP_ACOM IN (1,2,8)
GROUP BY  TO_CHAR(CONTADOR.DATA,'MM/YYYY')  

UNION

/*Internados no periodo*/
SELECT  TO_CHAR(CONTADOR.DATA,'MM/YYYY')MES_ANO,
        0 PAC_INT_00H,
        COUNT(*) ENT_INTERNADOS,
        0 ENT_TRANSF,
        0 SAI_ALTAS,
        0 SAI_TRANSFPARA,
        0 SAI_OBITOS,
        0 TOTALLEITO
        
FROM    DBAMV.ATENDIME,
        DBAMV.UNID_INT,
        DBAMV.LEITO,
        DBAMV.MOV_INT,
        DBAMV.CONVENIO,
        ( SELECT ( (@p_datai) - 1 ) + ROWNUM DATA
          FROM DBAMV.CID
          WHERE ( (@p_datai) - 1 ) + ROWNUM <= (@p_dataf)) CONTADOR
          
WHERE LEITO.CD_UNID_INT = UNID_INT.CD_UNID_INT
  AND LEITO.CD_LEITO = MOV_INT.CD_LEITO
  AND TRUNC( DT_MOV_INT ) = TRUNC( CONTADOR.DATA )
  AND MOV_INT.TP_MOV = 'I'
  AND ATENDIME.CD_ATENDIMENTO = MOV_INT.CD_ATENDIMENTO
  AND ( ATENDIME.TP_ATENDIMENTO IN ('I', 'H') )
  AND ATENDIME.CD_CONVENIO = CONVENIO.CD_CONVENIO
  AND (ATENDIME.CD_MULTI_EMPRESA = 1)
  AND UNID_INT.CD_UNID_INT IN (2,11,26)
  AND  LEITO.CD_TIP_ACOM IN (1,2,8)
    
GROUP BY TO_CHAR(CONTADOR.DATA,'MM/YYYY')

UNION

/*Pacientes transferidos "de" no periodo*/
SELECT  TO_CHAR(CONTADOR.DATA,'MM/YYYY')MES_ANO,
        0 PAC_INT_00H,
        0 ENT_INTERNADOS,
        COUNT(*) ENT_TRANSF,
        0 SAI_ALTAS,
        0 SAI_TRANSFPARA,
        0 SAI_OBITOS,
        0 TOTALLEITO
        
FROM    DBAMV.MOV_INT,
        DBAMV.UNID_INT,
        DBAMV.UNID_INT UNID_INT1,
        DBAMV.LEITO,
        DBAMV.LEITO LEITO1,
        DBAMV.ATENDIME,
        DBAMV.CONVENIO,
        ( SELECT ( (@p_datai) - 1 ) + ROWNUM DATA
            FROM DBAMV.CID
           WHERE ( (@p_datai) - 1 ) + ROWNUM <= (@p_dataf) ) CONTADOR
WHERE   MOV_INT.TP_MOV = 'O'
  AND   TRUNC( MOV_INT.DT_MOV_INT ) = TRUNC(CONTADOR.DATA)
  AND   MOV_INT.CD_LEITO = LEITO.CD_LEITO
  AND   MOV_INT.CD_LEITO_ANTERIOR = LEITO1.CD_LEITO
  AND   LEITO1.CD_UNID_INT = UNID_INT1.CD_UNID_INT
  AND   UNID_INT.CD_UNID_INT <> UNID_INT1.CD_UNID_INT
  AND   LEITO.CD_UNID_INT = UNID_INT.CD_UNID_INT
  AND   ATENDIME.CD_ATENDIMENTO = MOV_INT.CD_ATENDIMENTO
  AND   ATENDIME.TP_ATENDIMENTO IN ('I', 'H')
  AND   ATENDIME.CD_CONVENIO = CONVENIO.CD_CONVENIO
  AND   ATENDIME.CD_MULTI_EMPRESA = 1
  AND   UNID_INT.CD_UNID_INT IN (2,11,26)
  AND   LEITO.CD_TIP_ACOM IN (1,2,8)
    
GROUP BY TO_CHAR(CONTADOR.DATA,'MM/YYYY')

UNION

/*PACIENTES DE ALTA NO PERIODO*/
SELECT  TO_CHAR(CONTADOR.DATA,'MM/YYYY')MES_ANO,
        0 PAC_INT_00H,
        0 ENT_INTERNADOS,
        0 ENT_TRANSF,
        COUNT(*) SAI_ALTAS,
        0 SAI_TRANSFPARA,
        0 SAI_OBITOS,
        0 TOTALLEITO

FROM    DBAMV.ATENDIME,
        DBAMV.UNID_INT,
        DBAMV.LEITO,
        DBAMV.MOT_ALT,
        DBAMV.CONVENIO,
        ( SELECT ( (@p_datai) - 1 ) + ROWNUM DATA
            FROM DBAMV.CID
           WHERE ( (@p_datai) - 1 ) + ROWNUM <= (@p_dataf) ) CONTADOR
           
WHERE  LEITO.CD_LEITO = ATENDIME.CD_LEITO
  AND  MOT_ALT.CD_MOT_ALT = ATENDIME.CD_MOT_ALT
  AND  UNID_INT.CD_UNID_INT = LEITO.CD_UNID_INT
  AND  TRUNC( ATENDIME.DT_ALTA ) = TRUNC(CONTADOR.DATA)
  AND  MOT_ALT.TP_MOT_ALTA <> 'O'
  AND  ATENDIME.TP_ATENDIMENTO = 'I'
  AND  ATENDIME.CD_CONVENIO = CONVENIO.CD_CONVENIO
  AND  ATENDIME.CD_MULTI_EMPRESA = 1
  AND  UNID_INT.CD_UNID_INT IN (2,11,26)
  AND  LEITO.CD_TIP_ACOM IN (1,2,8)
    
GROUP BY TO_CHAR(CONTADOR.DATA,'MM/YYYY')

UNION

/*Pacientes transferidos para outras unidades no periodo*/
SELECT  TO_CHAR(CONTADOR.DATA,'MM/YYYY')MES_ANO,
        0 PAC_INT_00H,
        0 ENT_INTERNADOS,
        0 ENT_TRANSF,
        0 SAI_ALTAS,
        COUNT(*) SAI_TRANSFPARA,
        0 SAI_OBITOS,
        0 TOTALLEITO
       
FROM   DBAMV.MOV_INT,
       DBAMV.UNID_INT,
       DBAMV.UNID_INT UNID_INT1,
       DBAMV.LEITO,
       DBAMV.LEITO LEITO1,
       DBAMV.ATENDIME,
       DBAMV.CONVENIO,
       ( SELECT ( (@p_datai) - 1 ) + ROWNUM DATA
            FROM DBAMV.CID
           WHERE ( (@p_datai) - 1 ) + ROWNUM <= (@p_dataf) ) CONTADOR
           
WHERE  TRUNC( MOV_INT.DT_MOV_INT ) = TRUNC(CONTADOR.DATA)
  AND  MOV_INT.TP_MOV = 'O'
  AND  MOV_INT.CD_LEITO_ANTERIOR = LEITO.CD_LEITO
  AND  MOV_INT.CD_LEITO = LEITO1.CD_LEITO
  AND  LEITO1.CD_UNID_INT = UNID_INT1.CD_UNID_INT
  AND  UNID_INT.CD_UNID_INT <> UNID_INT1.CD_UNID_INT
  AND  LEITO.CD_UNID_INT = UNID_INT.CD_UNID_INT
  AND  ATENDIME.CD_ATENDIMENTO = MOV_INT.CD_ATENDIMENTO
  AND  ATENDIME.TP_ATENDIMENTO IN ('I', 'H')
  AND  ATENDIME.CD_CONVENIO = CONVENIO.CD_CONVENIO
  AND  ATENDIME.CD_MULTI_EMPRESA = 1
  AND  UNID_INT.CD_UNID_INT IN (2,11,26)
  AND  LEITO.CD_TIP_ACOM IN (1,2,8)
    
GROUP BY TO_CHAR(CONTADOR.DATA,'MM/YYYY')

UNION

/*Paciente com saida por obito no periodo*/
SELECT  TO_CHAR(CONTADOR.DATA,'MM/YYYY')MES_ANO,
        0 PAC_INT_00H,
        0 ENT_INTERNADOS,
        0 ENT_TRANSF,
        0 SAI_ALTAS,
        0 SAI_TRANSFPARA,
        COUNT(*) SAI_OBITOS,
        0 TOTALLEITO
        
FROM    DBAMV.ATENDIME,
        DBAMV.UNID_INT,
        DBAMV.LEITO,
        DBAMV.MOT_ALT,
        DBAMV.CONVENIO,
        ( SELECT ( (@p_datai) - 1 ) + ROWNUM DATA
            FROM DBAMV.CID
           WHERE ( (@p_datai) - 1 ) + ROWNUM <= (@p_dataf) ) CONTADOR
WHERE   LEITO.CD_LEITO = ATENDIME.CD_LEITO
  AND   MOT_ALT.CD_MOT_ALT = ATENDIME.CD_MOT_ALT
  AND   LEITO.CD_UNID_INT = UNID_INT.CD_UNID_INT
  AND   TRUNC( ATENDIME.DT_ALTA ) = TRUNC(CONTADOR.DATA)
  AND   MOT_ALT.TP_MOT_ALTA = 'O'
  AND   ATENDIME.TP_ATENDIMENTO = 'I'
  AND   ATENDIME.CD_CONVENIO = CONVENIO.CD_CONVENIO
  AND   ATENDIME.CD_MULTI_EMPRESA = 1
  AND   UNID_INT.CD_UNID_INT IN (2,11,26)
  
GROUP BY TO_CHAR(CONTADOR.DATA,'MM/YYYY')
        )
        GROUP BY MES_ANO
ORDER BY 1
)
