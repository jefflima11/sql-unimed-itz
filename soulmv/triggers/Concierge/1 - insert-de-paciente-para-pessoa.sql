-- Created by JEFFERSON LIMA

INSERT INTO DBAMV.PT_PESSOA(CD_PESSOA,NM_NOME,DOC_IDENT_ID,NR_DOCUMENTO,TELEFONE,NM_SOCIAL,SN_UTILIZA_NOME_SOCIAL,SN_VISITANTE_RESTRITO) 

SELECT 
    SEQ_PT_PESSOA.NEXTVAL AS CD_PESSOA,
    P.NM_PACIENTE AS NM_NOME,
    1 AS DOC_IDENT_ID,
    P.NR_CPF AS NR_DOCUMENTO,
    P.NR_CELULAR AS TELEFONE,
    P.NM_SOCIAL_PACIENTE AS NM_SOCIAL,
    P.SN_UTILIZA_NOME_SOCIAL,
    'N' AS SN_VISITANTE_RESTRITO
FROM 
    DBAMV.PACIENTE P
WHERE  
    P.NM_PACIENTE NOT IN (SELECT NM_NOME FROM DBAMV.PT_PESSOA)
