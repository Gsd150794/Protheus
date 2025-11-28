#include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: MOMS074
Autor-------------: Jose Gavetti
Data da Criacao---: 24/09/2025
Descrição---------: Rotina para gravar a memória de cálculo das premissas
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MOMS074()

   Local _aTables     := {"SC5","SF2","SC6","Z38","Z39","Z40","Z41"}  As Array   
   Local _aParRet     := {}                                           As Array
   Local _aParAux     := {}                                           As Array
   Local _bOK         := {|| U_MOMS074Val() }                         As Block
   Local _nI          := 0                                            As Numeric
   Local _lRet        := .F.                                          As Logical

   Private _lScheduler:= FWGetRunSchedule()                           As Logical

   // Verifica a necessidade de criar um ambiente, caso nao esteja criado anteriormente um ambiente, pois ocorrera erro
   If Select("SX3") <= 0
      RPCSetType(3) // Nao consome licensas
      RpcSetEnv("01","01",,,,"SCHEDULE_PC_LIBERADOS",_aTables)// Seta o ambiente com a empresa 01 filial 01
      _lScheduler:=.T.
   EndIf

   _dDtDia  := Date()
   _nMes    := Val(Substr(Dtos(_dDtDia),5,2))
   _nAno    := Val(Substr(Dtos(_dDtDia),1,4))
   _dDtIni  := Ctod("01/"+StrZero(_nMes,2)+"/"+StrZero(_nAno,4))
   MV_PAR01 := StrZero(_nMes,2)+StrZero(_nAno,4)

   If _lScheduler
      MOMS74INT()
   Else
      aAdd( _aParAux , { 1 , "Digite o Periodo (MM/AAAA)", MV_PAR01, "@R 99/9999", "U_MOMS074Val()","","", 070 , .T. } )

      For _nI := 1 To Len( _aParAux )
         aAdd( _aParRet , _aParAux[_nI][03] )
      Next _nI
      
      While .T.
         // ParamBox( _aParAux , cTitle                                                       , @aRet    ,[bOk], [ aButtons ] [ lCentered ] [ nPosX ] [ nPosy ] [ oDlgWizard ] [ cLoad ] [ lCanSave ] [ lUserSave ] 
         If ParamBox( _aParAux , " Percentual de Meta e Percentual Acumulado do Coordenador " , @_aParRet, _bOK, /*aButtons*/,/*lCentered*/,/*nPosX*/,/*nPosy*/,/*oDlgWizard*/,/*cLoad*/,.T.         ,.T.          )

            _dDtDia := MV_PAR01
            _dDtIni := Ctod("01/"+Left(_dDtDia,2)+"/"+Right(_dDtDia,4))//Primeiro dia do mes.
            _dDtDia := LastDate(_dDtIni)//Retorna a Data do ùltimo dia do mes da Data Passada
               
            FWMSGRUN( ,{|oProc|  _lRet := MOMS74INT(oProc) } , "Hora Inicial: "+Time()+" Selecionando notas... ","Lendo de "+Dtoc(_dDtIni)+" até "+Dtoc(_dDtDia) )
               
            If _lRet .And. !_lScheduler
               U_ITMSG("Calculo de premissas gravado com sucesso!","Concluido",,2) // Confirmar
            EndIf 

         EndIf 

         Exit

      EndDo
      
   EndIf

Return

/*
===============================================================================================================================
Programa----------: MOMS074Val()
Autor-------------: Jose Gavetti
Data da Criacao---: 01/09/2025
Descrição---------: Validações do Parambox.
Parametros--------: Nenhum
Retorno-----------: .T. ou .F.
===============================================================================================================================
*/
User Function MOMS074Val() As Logical

   Local _cMes := MV_PAR01
   Local _lRet := .T.

   _cMes:= RIGHT(_cMes,4)+LEFT(_cMes,2)

   Z38->(DBSetOrder(2))
   IF !Z38->(DbSeek( FWxFilial() + _cMes ))
      U_ITMSG("Não há premissas cadastradas para esse Ano+Mes "+MV_PAR01,'Atenção!',"Selecione um mes com premissas cadastradas.",1) // CANCEL
      _lRet := .F.
   EndIf

   Z38->(DBSetOrder(1))

Return _lRet

/*
===============================================================================================================================
Programa----------: MOMS74INT
Autor-------------: Jose Gavetti
Data da Criacao---: 24/09/2025
Descrição---------: Rotina para gravar a memória de cálculo das premissas
Parametros--------: oProc As Object
Retorno-----------: .T.
===============================================================================================================================
*/
Static Function MOMS74INT(oProc As Object) As Logical

   Local _cAlias    := GetNextAlias()     As Character
   Local _cQry      := ""                 As Character
   Local _cPeriod   := ""                 As Character
   Local _nTot      := 0                  As Numeric
   Local _nConta    := 0                  As Numeric
   Local _nPercFat  := 0                  As Numeric
   Local _lRet      := .T.                As Logical

   _cPeriod:= RIGHT(MV_PAR01,4)+LEFT(MV_PAR01,2)

   DbSelectArea("Z41")
   Z41->(DbSetOrder(1))

   _cQry +=  "   WITH SD2 AS "
   _cQry +=  "        (SELECT Z38_COD       AS D2_PREMISSA,  "
   _cQry +=  "                Z38_PERIOD    AS D2_PERIOD,  "
   _cQry +=  "                Z38_TPCALC    AS D2_TPCALC,  "
   _cQry +=  "                F2_EST        AS D2_EST,  "
   _cQry +=  "                F2_VEND1      AS D2_VEND1,  "
   _cQry +=  "                F2_VEND2      AS D2_VEND2,  "
   _cQry +=  "                F2_VEND3      AS D2_VEND3,  "
   _cQry +=  "                F2_VEND4      AS D2_VEND4,  "
   _cQry +=  "                CASE  "
   _cQry +=  "                    WHEN SC5.C5_I_OPER = '05' THEN SC5R.C5_CLIENTE  "
   _cQry +=  "                    ELSE D2_CLIENTE  "
   _cQry +=  "                END           AS D2_CLIENTE,  "
   _cQry +=  "                CASE  "
   _cQry +=  "                    WHEN SC5.C5_I_OPER = '05' THEN SC5R.C5_LOJACLI  "
   _cQry +=  "                    ELSE D2_LOJA  "
   _cQry +=  "                END           AS D2_LOJA,  "
   _cQry +=  "                D2_COD        AS D2_COD,  "
   _cQry +=  "                CASE  "
   _cQry +=  "                    WHEN Z39_TIPO = 'A' AND Z39_TPCONV = 'M'  "
   _cQry +=  "                    THEN  "
   _cQry +=  "                        (D2_QUANT - D2_QTDEDEV) * Z39_FATOR  "
   _cQry +=  "                    WHEN Z39_TIPO = 'A'  "
   _cQry +=  "                    THEN  "
   _cQry +=  "                        (D2_QUANT - D2_QTDEDEV) / Z39_FATOR  "
   _cQry +=  "                    ELSE  "
   _cQry +=  "                        0  "
   _cQry +=  "                END           AS FAT_A,  "
   _cQry +=  "                CASE  "
   _cQry +=  "                    WHEN Z39_TIPO = 'B' AND Z39_TPCONV = 'M'  "
   _cQry +=  "                    THEN  "
   _cQry +=  "                        (D2_QUANT - D2_QTDEDEV) * Z39_FATOR  "
   _cQry +=  "                    WHEN Z39_TIPO = 'B'  "
   _cQry +=  "                    THEN  "
   _cQry +=  "                        (D2_QUANT - D2_QTDEDEV) / Z39_FATOR  "
   _cQry +=  "                    ELSE  "
   _cQry +=  "                        0  "
   _cQry +=  "                END           AS FAT_B  "
   _cQry +=  "           FROM Z38010  Z38,  "
   _cQry +=  "                Z39010  Z39,  "
   _cQry +=  "                SF2010  SF2,  "
   _cQry +=  "                SD2010  SD2,  "
   _cQry +=  "                ZAY010  ZAY,  "
   _cQry +=  "                SC5010  SC5,  "
   _cQry +=  "                SC5010  SC5R  "
   _cQry +=  "          WHERE Z39_FILIAL = ' '  "
   _cQry +=  "                AND Z39_PERIOD = '"+_cPeriod+"' "
   _cQry +=  "                AND Z39_PRODUT = D2_COD  "
   _cQry +=  "                AND Z39.D_E_L_E_T_ = ' '  "
   _cQry +=  "                AND Z38_FILIAL = Z39_FILIAL  "
   _cQry +=  "                AND Z38_COD = Z39_COD  "
   _cQry +=  "                AND Z38_PERIOD = Z39_PERIOD  "
   _cQry +=  "                AND Z38_MSBLQL <> '1'  "
   _cQry +=  "                AND Z38.D_E_L_E_T_ = ' '  "
   _cQry +=  "                AND SUBSTR (F2_EMISSAO, 1, 6) = Z39_PERIOD  "
   _cQry +=  "                AND F2_TIPO = 'N'  "
   _cQry +=  "                AND SF2.D_E_L_E_T_ = ' '  "
   _cQry +=  "                AND D2_FILIAL = F2_FILIAL  "
   _cQry +=  "                AND D2_DOC = F2_DOC  "
   _cQry +=  "                AND D2_SERIE = F2_SERIE  "
   _cQry +=  "                AND (D2_QUANT - D2_QTDEDEV) <> 0  "
   _cQry +=  "                AND SD2.D_E_L_E_T_ = ' '  "
   _cQry +=  "                AND ZAY_FILIAL = ' '  "
   _cQry +=  "                AND ZAY_CF = D2_CF  "
   _cQry +=  "                AND ZAY_TPOPER = 'V'  "
   _cQry +=  "                AND ZAY.D_E_L_E_T_ = ' '  "
   _cQry +=  "                AND SC5.C5_FILIAL = D2_FILIAL  "
   _cQry +=  "                AND SC5.C5_NUM = D2_PEDIDO  "
   _cQry +=  "                AND SC5.D_E_L_E_T_ = ' '  "
   _cQry +=  "                AND SC5R.C5_FILIAL(+) = SC5.C5_FILIAL  "
   _cQry +=  "                AND SC5R.C5_NUM(+) = SC5.C5_I_PVREM  "
   _cQry +=  "                AND SC5R.D_E_L_E_T_(+) = ' ')  "
   _cQry +=  "  SELECT D2_PREMISSA     AS PREMISSA,  "
   _cQry +=  "         D2_PERIOD       AS PERIODO,  "
   _cQry +=  "         D2_TPCALC       AS TPCALC,  "
   _cQry +=  "         'GERENTE'       AS TPREG,  "
   _cQry +=  "         D2_VEND3        AS GERENTE,  "
   _cQry +=  "         ' '             AS COORDENADOR,  "
   _cQry +=  "         ' '             AS SUPERVISOR,  "
   _cQry +=  "         ' '             AS VENDEDOR,  "
   _cQry +=  "         ' '             AS REGIAO,  "
   _cQry +=  "         ' '             AS UF,  "
   _cQry +=  "         ' '             AS MUNICIPIO,  "
   _cQry +=  "         ' '             AS SEGMENTO,  "
   _cQry +=  "         ' '             AS REDE,  "
   _cQry +=  "         ' '             AS CLIENTE,  "
   _cQry +=  "         ' '             AS LOJA,  "
   _cQry +=  "         A3_NOME         AS DESCRICAO,  "
   _cQry +=  "         SUM (FAT_A)     AS FAT_A,  "
   _cQry +=  "         SUM (FAT_B)     AS FAT_B  "
   _cQry +=  "    FROM SD2, SA3010 SA3  "
   _cQry +=  "   WHERE A3_FILIAL = ' ' AND A3_COD = D2_VEND3 AND SA3.D_E_L_E_T_ = ' '  "
   _cQry +=  "GROUP BY D2_PREMISSA,  "
   _cQry +=  "         D2_PERIOD,  "
   _cQry +=  "         D2_TPCALC,  "
   _cQry +=  "         D2_VEND3,  "
   _cQry +=  "         A3_NOME  "
   _cQry +=  "UNION  "
   _cQry +=  "  SELECT D2_PREMISSA       AS PREMISSA,  "
   _cQry +=  "         D2_PERIOD         AS PERIODO,  "
   _cQry +=  "         D2_TPCALC         AS TPCALC,  "
   _cQry +=  "         'COORDENADOR'     AS TPREG,  "
   _cQry +=  "         D2_VEND3          AS GERENTE,  "
   _cQry +=  "         D2_VEND2          AS COORDENADOR,  "
   _cQry +=  "         ' '               AS SUPERVISOR,  "
   _cQry +=  "         ' '               AS VENDEDOR,  "
   _cQry +=  "         ' '               AS REGIAO,  "
   _cQry +=  "         ' '               AS UF,  "
   _cQry +=  "         ' '               AS MUNICIPIO,  "
   _cQry +=  "         ' '               AS SEGMENTO,  "
   _cQry +=  "         ' '               AS REDE,  "
   _cQry +=  "         ' '               AS CLIENTE,  "
   _cQry +=  "         ' '               AS LOJA,  "
   _cQry +=  "         A3_NOME           AS DESCRICAO,  "
   _cQry +=  "         SUM (FAT_A)       AS FAT_A,  "
   _cQry +=  "         SUM (FAT_B)       AS FAT_B  "
   _cQry +=  "    FROM SD2, SA3010 SA3  "
   _cQry +=  "   WHERE     D2_VEND2 <> ' '  "
   _cQry +=  "         AND A3_FILIAL = ' '  "
   _cQry +=  "         AND A3_COD = D2_VEND2  "
   _cQry +=  "         AND SA3.D_E_L_E_T_ = ' '  "
   _cQry +=  "GROUP BY D2_PREMISSA,  "
   _cQry +=  "         D2_PERIOD,  "
   _cQry +=  "         D2_TPCALC,  "
   _cQry +=  "         D2_VEND3,  "
   _cQry +=  "         D2_VEND2,  "
   _cQry +=  "         A3_NOME  "
   _cQry +=  "UNION  "
   _cQry +=  "  SELECT D2_PREMISSA      AS PREMISSA,  "
   _cQry +=  "         D2_PERIOD        AS PERIODO,  "
   _cQry +=  "         D2_TPCALC        AS TPCALC,  "
   _cQry +=  "         'SUPERVISOR'     AS TPREG,  "
   _cQry +=  "         D2_VEND3         AS GERENTE,  "
   _cQry +=  "         D2_VEND2         AS COORDENADOR,  "
   _cQry +=  "         D2_VEND4         AS SUPERVISOR,  "
   _cQry +=  "         ' '              AS VENDEDOR,  "
   _cQry +=  "         ' '              AS REGIAO,  "
   _cQry +=  "         ' '              AS UF,  "
   _cQry +=  "         ' '              AS MUNICIPIO,  "
   _cQry +=  "         ' '              AS SEGMENTO,  "
   _cQry +=  "         ' '              AS REDE,  "
   _cQry +=  "         ' '              AS CLIENTE,  "
   _cQry +=  "         ' '              AS LOJA,  "
   _cQry +=  "         A3_NOME          AS DESCRICAO,  "
   _cQry +=  "         SUM (FAT_A)      AS FAT_A,  "
   _cQry +=  "         SUM (FAT_B)      AS FAT_B  "
   _cQry +=  "    FROM SD2, SA3010 SA3  "
   _cQry +=  "   WHERE     D2_VEND4 <> ' '  "
   _cQry +=  "         AND A3_FILIAL = ' '  "
   _cQry +=  "         AND A3_COD = D2_VEND4  "
   _cQry +=  "         AND SA3.D_E_L_E_T_ = ' '  "
   _cQry +=  "GROUP BY D2_PREMISSA,  "
   _cQry +=  "         D2_PERIOD,  "
   _cQry +=  "         D2_TPCALC,  "
   _cQry +=  "         D2_VEND3,  "
   _cQry +=  "         D2_VEND2,  "
   _cQry +=  "         D2_VEND4,  "
   _cQry +=  "         A3_NOME  "
   _cQry +=  "UNION  "
   _cQry +=  "  SELECT D2_PREMISSA     AS PREMISSA,  "
   _cQry +=  "         D2_PERIOD       AS PERIODO,  "
   _cQry +=  "         D2_TPCALC       AS TPCALC,  "
   _cQry +=  "         'VENDEDOR'      AS TPREG,  "
   _cQry +=  "         D2_VEND3        AS GERENTE,  "
   _cQry +=  "         D2_VEND2        AS COORDENADOR,  "
   _cQry +=  "         D2_VEND4        AS SUPERVISOR,  "
   _cQry +=  "         D2_VEND1        AS VENDEDOR,  "
   _cQry +=  "         ' '             AS REGIAO,  "
   _cQry +=  "         ' '             AS UF,  "
   _cQry +=  "         ' '             AS MUNICIPIO,  "
   _cQry +=  "         ' '             AS SEGMENTO,  "
   _cQry +=  "         ' '             AS REDE,  "
   _cQry +=  "         ' '             AS CLIENTE,  "
   _cQry +=  "         ' '             AS LOJA,  "
   _cQry +=  "         A3_NOME         AS DESCRICAO,  "
   _cQry +=  "         SUM (FAT_A)     AS FAT_A,  "
   _cQry +=  "         SUM (FAT_B)     AS FAT_B  "
   _cQry +=  "    FROM SD2, SA3010 SA3  "
   _cQry +=  "   WHERE     D2_VEND1 <> ' '  "
   _cQry +=  "         AND A3_FILIAL = ' '  "
   _cQry +=  "         AND A3_COD = D2_VEND1  "
   _cQry +=  "         AND SA3.D_E_L_E_T_ = ' '  "
   _cQry +=  "GROUP BY D2_PREMISSA,  "
   _cQry +=  "         D2_PERIOD,  "
   _cQry +=  "         D2_TPCALC,  "
   _cQry +=  "         D2_VEND3,  "
   _cQry +=  "         D2_VEND2,  "
   _cQry +=  "         D2_VEND4,  "
   _cQry +=  "         D2_VEND1,  "
   _cQry +=  "         A3_NOME  "
   _cQry +=  "UNION  "
   _cQry +=  "  SELECT D2_PREMISSA    AS PREMISSA,  "
   _cQry +=  "         D2_PERIOD      AS PERIODO,  "
   _cQry +=  "         D2_TPCALC      AS TPCALC,  "
   _cQry +=  "         'REGIAO'       AS TPREG,  "
   _cQry +=  "         ' '            AS GERENTE,  "
   _cQry +=  "         ' '            AS COORDENADOR,  "
   _cQry +=  "         ' '            AS SUPERVISOR,  "
   _cQry +=  "         ' '            AS VENDEDOR,  "
   _cQry +=  "         A1_I_REGIA     AS REGIAO,  "
   _cQry +=  "         ' '            AS UF,  "
   _cQry +=  "         ' '            AS MUNICIPIO,  "
   _cQry +=  "         ' '            AS SEGMENTO,  "
   _cQry +=  "         ' '            AS REDE,  "
   _cQry +=  "         ' '            AS CLIENTE,  "
   _cQry +=  "         ' '            AS LOJA,  "
   _cQry +=  "         CASE A1_I_REGIA  "
   _cQry +=  "             WHEN 'CO' THEN 'CENTRO OESTE'  "
   _cQry +=  "             WHEN 'N' THEN 'NORTE'  "
   _cQry +=  "             WHEN 'NE' THEN 'NORDESTE'  "
   _cQry +=  "             WHEN 'S' THEN 'SUL'  "
   _cQry +=  "             WHEN 'SE' THEN 'SUDESTE'  "
   _cQry +=  "             ELSE 'OUTROS'  "
   _cQry +=  "         END            AS DESCRICAO,  "
   _cQry +=  "         SUM (FAT_A)    AS FAT_A,  "
   _cQry +=  "         SUM (FAT_B)    AS FAT_B  "
   _cQry +=  "    FROM SD2, SA1010 SA1  "
   _cQry +=  "   WHERE     A1_FILIAL = ' '  "
   _cQry +=  "         AND A1_COD = D2_CLIENTE  "
   _cQry +=  "         AND A1_LOJA = D2_LOJA  "
   _cQry +=  "         AND SA1.D_E_L_E_T_ = ' '  "
   _cQry +=  "GROUP BY D2_PREMISSA,  "
   _cQry +=  "         D2_PERIOD,  "
   _cQry +=  "         D2_TPCALC,  "
   _cQry +=  "         A1_I_REGIA  "
   _cQry +=  "UNION  "
   _cQry +=  "  SELECT D2_PREMISSA     AS PREMISSA,  "
   _cQry +=  "         D2_PERIOD       AS PERIODO,  "
   _cQry +=  "         D2_TPCALC       AS TPCALC,  "
   _cQry +=  "         'UF'            AS TPREG,  "
   _cQry +=  "         ' '             AS GERENTE,  "
   _cQry +=  "         ' '             AS COORDENADOR,  "
   _cQry +=  "         ' '             AS SUPERVISOR,  "
   _cQry +=  "         ' '             AS VENDEDOR,  "
   _cQry +=  "         A1_I_REGIA      AS REGIAO,  "
   _cQry +=  "         D2_EST          AS UF,  "
   _cQry +=  "         ' '             AS MUNICIPIO,  "
   _cQry +=  "         ' '             AS SEGMENTO,  "
   _cQry +=  "         ' '             AS REDE,  "
   _cQry +=  "         ' '             AS CLIENTE,  "
   _cQry +=  "         ' '             AS LOJA,  "
   _cQry +=  "         D2_EST          AS DESCRICAO,  "
   _cQry +=  "         SUM (FAT_A)     AS FAT_A,  "
   _cQry +=  "         SUM (FAT_B)     AS FAT_B  "
   _cQry +=  "    FROM SD2, SA1010 SA1  "
   _cQry +=  "   WHERE     A1_FILIAL = ' '  "
   _cQry +=  "         AND A1_COD = D2_CLIENTE  "
   _cQry +=  "         AND A1_LOJA = D2_LOJA  "
   _cQry +=  "         AND SA1.D_E_L_E_T_ = ' '  "
   _cQry +=  "GROUP BY D2_PREMISSA,  "
   _cQry +=  "         D2_PERIOD,  "
   _cQry +=  "         D2_TPCALC,  "
   _cQry +=  "         A1_I_REGIA,  "
   _cQry +=  "         D2_EST  "
   _cQry +=  "UNION  "
   _cQry +=  "  SELECT D2_PREMISSA     AS PREMISSA,  "
   _cQry +=  "         D2_PERIOD       AS PERIODO,  "
   _cQry +=  "         D2_TPCALC       AS TPCALC,  "
   _cQry +=  "         'MUNICIPIO'     AS TPREG,  "
   _cQry +=  "         ' '             AS GERENTE,  "
   _cQry +=  "         ' '             AS COORDENADOR,  "
   _cQry +=  "         ' '             AS SUPERVISOR,  "
   _cQry +=  "         ' '             AS VENDEDOR,  "
   _cQry +=  "         A1_I_REGIA      AS REGIAO,  "
   _cQry +=  "         D2_EST          AS UF,  "
   _cQry +=  "         A1_COD_MUN      AS MUNICIPIO,  "
   _cQry +=  "         ' '             AS SEGMENTO,  "
   _cQry +=  "         ' '             AS REDE,  "
   _cQry +=  "         ' '             AS CLIENTE,  "
   _cQry +=  "         ' '             AS LOJA,  "
   _cQry +=  "         CC2_MUN         AS DESCRICAO,  "
   _cQry +=  "         SUM (FAT_A)     AS FAT_A,  "
   _cQry +=  "         SUM (FAT_B)     AS FAT_B  "
   _cQry +=  "    FROM SD2, SA1010 SA1, CC2010 CC2  "
   _cQry +=  "   WHERE     A1_FILIAL = ' '  "
   _cQry +=  "         AND A1_COD = D2_CLIENTE  "
   _cQry +=  "         AND A1_LOJA = D2_LOJA  "
   _cQry +=  "         AND SA1.D_E_L_E_T_ = ' '  "
   _cQry +=  "         AND CC2_FILIAL = ' '  "
   _cQry +=  "         AND CC2_EST = D2_EST  "
   _cQry +=  "         AND CC2_CODMUN = A1_COD_MUN  "
   _cQry +=  "         AND CC2.D_E_L_E_T_ = ' '  "
   _cQry +=  "GROUP BY D2_PREMISSA,  "
   _cQry +=  "         D2_PERIOD,  "
   _cQry +=  "         D2_TPCALC,  "
   _cQry +=  "         A1_I_REGIA,  "
   _cQry +=  "         D2_EST,  "
   _cQry +=  "         A1_COD_MUN,  "
   _cQry +=  "         CC2_MUN  "
   _cQry +=  "UNION  "
   _cQry +=  "  SELECT D2_PREMISSA     AS PREMISSA,  "
   _cQry +=  "         D2_PERIOD       AS PERIODO,  "
   _cQry +=  "         D2_TPCALC       AS TPCALC,  "
   _cQry +=  "         'SEGMENTO'      AS TPREG,  "
   _cQry +=  "         ' '             AS GERENTE,  "
   _cQry +=  "         ' '             AS COORDENADOR,  "
   _cQry +=  "         ' '             AS SUPERVISOR,  "
   _cQry +=  "         ' '             AS VENDEDOR,  "
   _cQry +=  "         ' '             AS REGIAO,  "
   _cQry +=  "         ' '             AS UF,  "
   _cQry +=  "         ' '             AS MUNICIPIO,  "
   _cQry +=  "         A1_I_GRCLI      AS SEGMENTO,  "
   _cQry +=  "         ' '             AS REDE,  "
   _cQry +=  "         ' '             AS CLIENTE,  "
   _cQry +=  "         ' '             AS LOJA,  "
   _cQry +=  "         ZZ6_DESCRO      AS DESCRICAO,  "
   _cQry +=  "         SUM (FAT_A)     AS FAT_A,  "
   _cQry +=  "         SUM (FAT_B)     AS FAT_B  "
   _cQry +=  "    FROM SD2, SA1010 SA1, ZZ6010 ZZ6  "
   _cQry +=  "   WHERE     A1_FILIAL = ' '  "
   _cQry +=  "         AND A1_COD = D2_CLIENTE  "
   _cQry +=  "         AND A1_LOJA = D2_LOJA  "
   _cQry +=  "         AND SA1.D_E_L_E_T_ = ' '  "
   _cQry +=  "         AND ZZ6_FILIAL = ' '  "
   _cQry +=  "         AND ZZ6_CODIGO = A1_I_GRCLI  "
   _cQry +=  "         AND ZZ6.D_E_L_E_T_ = ' '  "
   _cQry +=  "GROUP BY D2_PREMISSA,  "
   _cQry +=  "         D2_PERIOD,  "
   _cQry +=  "         D2_TPCALC,  "
   _cQry +=  "         A1_I_GRCLI,  "
   _cQry +=  "         ZZ6_DESCRO  "
   _cQry +=  "UNION  "
   _cQry +=  "  SELECT D2_PREMISSA     AS PREMISSA,  "
   _cQry +=  "         D2_PERIOD       AS PERIODO,  "
   _cQry +=  "         D2_TPCALC       AS TPCALC,  "
   _cQry +=  "         'REDE'          AS TPREG,  "
   _cQry +=  "         ' '             AS GERENTE,  "
   _cQry +=  "         ' '             AS COORDENADOR,  "
   _cQry +=  "         ' '             AS SUPERVISOR,  "
   _cQry +=  "         ' '             AS VENDEDOR,  "
   _cQry +=  "         ' '             AS REGIAO,  "
   _cQry +=  "         ' '             AS UF,  "
   _cQry +=  "         ' '             AS MUNICIPIO,  "
   _cQry +=  "         ' '             AS SEGMENTO,  "
   _cQry +=  "         A1_GRPVEN       AS REDE,  "
   _cQry +=  "         ' '             AS CLIENTE,  "
   _cQry +=  "         ' '             AS LOJA,  "
   _cQry +=  "         ACY_DESCRI      AS DESCRICAO,  "
   _cQry +=  "         SUM (FAT_A)     AS FAT_A,  "
   _cQry +=  "         SUM (FAT_B)     AS FAT_B  "
   _cQry +=  "    FROM SD2, SA1010 SA1, ACY010 ACY  "
   _cQry +=  "   WHERE     A1_FILIAL = ' '  "
   _cQry +=  "         AND A1_COD = D2_CLIENTE  "
   _cQry +=  "         AND A1_LOJA = D2_LOJA  "
   _cQry +=  "         AND SA1.D_E_L_E_T_ = ' '  "
   _cQry +=  "         AND ACY_FILIAL = ' '  "
   _cQry +=  "         AND ACY_GRPVEN = A1_GRPVEN  "
   _cQry +=  "         AND ACY.D_E_L_E_T_ = ' '  "
   _cQry +=  "GROUP BY D2_PREMISSA,  "
   _cQry +=  "         D2_PERIOD,  "
   _cQry +=  "         D2_TPCALC,  "
   _cQry +=  "         A1_GRPVEN,  "
   _cQry +=  "         ACY_DESCRI  "
   _cQry +=  "UNION  "
   _cQry +=  "  SELECT D2_PREMISSA                          AS PREMISSA,  "
   _cQry +=  "         D2_PERIOD                            AS PERIODO,  "
   _cQry +=  "         D2_TPCALC                            AS TPCALC,  "
   _cQry +=  "         'CLIENTE'                            AS TPREG,  "
   _cQry +=  "         ' '                                  AS GERENTE,  "
   _cQry +=  "         ' '                                  AS COORDENADOR,  "
   _cQry +=  "         ' '                                  AS SUPERVISOR,  "
   _cQry +=  "         ' '                                  AS VENDEDOR,  "
   _cQry +=  "         ' '                                  AS REGIAO,  "
   _cQry +=  "         ' '                                  AS UF,  "
   _cQry +=  "         ' '                                  AS MUNICIPIO,  "
   _cQry +=  "         ' '                                  AS SEGMENTO,  "
   _cQry +=  "         ' '                                  AS REDE,  "
   _cQry +=  "         D2_CLIENTE                           AS CLIENTE,  "
   _cQry +=  "         ' '                                  AS LOJA, (SELECT MIN (A1_NOME)  "
   _cQry +=  "          FROM SA1010 SA1  "
   _cQry +=  "          WHERE     A1_FILIAL = ' '  "
   _cQry +=  "                 AND A1_COD = D2_CLIENTE  "
   _cQry +=  "                 AND SA1.D_E_L_E_T_ = ' ')    DESCRICAO,  "
   _cQry +=  "         SUM (FAT_A)                          AS FAT_A,  "
   _cQry +=  "         SUM (FAT_B)                          AS FAT_B  "
   _cQry +=  "    FROM SD2  "
   _cQry +=  "GROUP BY D2_PREMISSA,  "
   _cQry +=  "         D2_PERIOD,  "
   _cQry +=  "         D2_TPCALC,  "
   _cQry +=  "         D2_CLIENTE  "
   _cQry +=  "UNION  "
   _cQry +=  "  SELECT D2_PREMISSA     AS PREMISSA,  "
   _cQry +=  "         D2_PERIOD       AS PERIODO,  "
   _cQry +=  "         D2_TPCALC       AS TPCALC,  "
   _cQry +=  "         'LOJA'          AS TPREG,  "
   _cQry +=  "         ' '             AS GERENTE,  "
   _cQry +=  "         ' '             AS COORDENADOR,  "
   _cQry +=  "         ' '             AS SUPERVISOR,  "
   _cQry +=  "         ' '             AS VENDEDOR,  "
   _cQry +=  "         A1_I_REGIA      AS REGIAO,  "
   _cQry +=  "         D2_EST          AS UF,  "
   _cQry +=  "         A1_COD_MUN      AS MUNICIPIO,  "
   _cQry +=  "         A1_I_GRCLI      AS SEGMENTO,  "
   _cQry +=  "         A1_GRPVEN       AS REDE,  "
   _cQry +=  "         D2_CLIENTE      AS CLIENTE,  "
   _cQry +=  "         D2_LOJA         AS LOJA,  "
   _cQry +=  "         A1_NOME         AS DESCRICAO,  "
   _cQry +=  "         SUM (FAT_A)     AS FAT_A,  "
   _cQry +=  "         SUM (FAT_B)     AS FAT_B  "
   _cQry +=  "    FROM SD2, SA1010 SA1  "
   _cQry +=  "   WHERE     A1_FILIAL = ' '  "
   _cQry +=  "         AND A1_COD = D2_CLIENTE  "
   _cQry +=  "         AND A1_LOJA = D2_LOJA  "
   _cQry +=  "         AND SA1.D_E_L_E_T_ = ' '  "
   _cQry +=  "GROUP BY D2_PREMISSA,  "
   _cQry +=  "         D2_PERIOD,  "
   _cQry +=  "         D2_TPCALC,  "
   _cQry +=  "         A1_I_REGIA,  "
   _cQry +=  "         D2_EST,  "
   _cQry +=  "         A1_COD_MUN,  "
   _cQry +=  "         A1_GRPVEN,  "
   _cQry +=  "         D2_CLIENTE,  "
   _cQry +=  "         D2_LOJA,  "
   _cQry +=  "         A1_NOME,  "
   _cQry +=  "         A1_I_GRCLI  "
   _cQry +=  "UNION  "
   _cQry +=  "  SELECT D2_PREMISSA     AS PREMISSA,  "
   _cQry +=  "         D2_PERIOD       AS PERIODO,  "
   _cQry +=  "         D2_TPCALC       AS TPCALC,  "
   _cQry +=  "         'ANALITICO'     AS TPREG,  "
   _cQry +=  "         D2_VEND3        AS GERENTE,  "
   _cQry +=  "         D2_VEND2        AS COORDENADOR,  "
   _cQry +=  "         D2_VEND4        AS SUPERVISOR,  "
   _cQry +=  "         D2_VEND1        AS VENDEDOR,  "
   _cQry +=  "         A1_I_REGIA      AS REGIAO,  "
   _cQry +=  "         D2_EST          AS UF,  "
   _cQry +=  "         A1_COD_MUN      AS MUNICIPIO,  "
   _cQry +=  "         A1_I_GRCLI      AS SEGMENTO,  "
   _cQry +=  "         A1_GRPVEN       AS REDE,  "
   _cQry +=  "         D2_CLIENTE      AS CLIENTE,  "
   _cQry +=  "         D2_LOJA         AS LOJA,  "
   _cQry +=  "         ' '             AS DESCRICAO,  "
   _cQry +=  "         SUM (FAT_A)     AS FAT_A,  "
   _cQry +=  "         SUM (FAT_B)     AS FAT_B  "
   _cQry +=  "    FROM SD2, SA1010 SA1  "
   _cQry +=  "   WHERE     A1_FILIAL = ' '  "
   _cQry +=  "         AND A1_COD = D2_CLIENTE  "
   _cQry +=  "         AND A1_LOJA = D2_LOJA  "
   _cQry +=  "         AND SA1.D_E_L_E_T_ = ' '  "
   _cQry +=  "GROUP BY D2_PREMISSA,  "
   _cQry +=  "         D2_PERIOD,  "
   _cQry +=  "         D2_TPCALC,  "
   _cQry +=  "         D2_VEND3,  "
   _cQry +=  "         D2_VEND2,  "
   _cQry +=  "         D2_VEND4,  "
   _cQry +=  "         D2_VEND1,  "
   _cQry +=  "         A1_I_REGIA,  "
   _cQry +=  "         D2_EST,  "
   _cQry +=  "         A1_COD_MUN,  "
   _cQry +=  "         A1_I_GRCLI,  "
   _cQry +=  "         A1_GRPVEN,  "
   _cQry +=  "         D2_CLIENTE,  "
   _cQry +=  "         D2_LOJA  "

   MPSysOpenQuery(_cQry,_cAlias)
   DBSelectArea(_cAlias)

   IF oProc <> Nil .And. !_lScheduler
      COUNT TO _nTot 
      _cTot := AllTrim(Str(_nTot))
      oProc:cCaption:=Time()+"-Preparando processamento de "+_cTot+" registros."
      ProcessMessages()
       (_cAlias)->(DbGoTop())
   EndIf

   IF _nTot = 0 .And. !_lScheduler
      U_ITMSG("Não foram encontrados registros para esses filtros.",'Atenção!',"Selecione outros filtros.",1) // CANCEL
      _lRet := .F.
   EndIf

   If _lRet 

      Z41DELET(_cPeriod) // Deleto os registros do periodo selecionado.
      
      While (_cAlias)->(!EOF())

         _nConta++
         _nPercFat:= 0

         If oProc <> Nil .And. !_lScheduler
            oProc:cCaption:='Quantidade de Registros Lidas: '+AllTrim(STR(_nConta))+ " / "+_cTot
            ProcessMessages()
         EndIf

         IF (_cAlias)->TPCALC = "1"
            _nPercFat := Round( ( ((_cAlias)->FAT_B / ((_cAlias)->FAT_A  + (_cAlias)->FAT_B )) *100 ) ,2) //Percentual Acumulado ? (( Qtd Leite Magro / ( QtdLeiteMago + QtdLeiteIntegral) ) * 100 )
         ElseIf (_cAlias)->TPCALC = "2"
            _nPercFat := Round( ( ((_cAlias)->FAT_B / ( (_cAlias)->FAT_A )) *100 ) ,2) //Percentual Acumulado ? (( Qtd Leite Magro / (QtdLeiteIntegral) ) * 100 )
         EndIf

         IF !Empty((_cAlias)->FAT_B) .And.Empty((_cAlias)->FAT_A) //SE SÓ TIVER BETA É 100%
            _nPercFat:=100//Faturamento
         EndIf

         Z41->(RecLock("Z41",.T.))
            Z41->Z41_TPREG   :=  (_cAlias)->TPREG
            Z41->Z41_COD     :=  (_cAlias)->PREMISSA
            Z41->Z41_PERIOD  :=  (_cAlias)->PERIODO
            Z41->Z41_TPCALC  :=  (_cAlias)->TPCALC
            Z41->Z41_VEND1   :=  (_cAlias)->VENDEDOR
            Z41->Z41_VEND2   :=  (_cAlias)->COORDENADOR
            Z41->Z41_VEND3   :=  (_cAlias)->GERENTE
            Z41->Z41_VEND4   :=  (_cAlias)->SUPERVISOR
            Z41->Z41_REGIAO  :=  (_cAlias)->REGIAO
            Z41->Z41_UF      :=  (_cAlias)->UF
            Z41->Z41_CODMUN  :=  (_cAlias)->MUNICIPIO
            Z41->Z41_GRCLI   :=  (_cAlias)->SEGMENTO
            Z41->Z41_GRPVEN  :=  (_cAlias)->REDE
            Z41->Z41_CLIENT  :=  (_cAlias)->CLIENTE
            Z41->Z41_LOJA    :=  (_cAlias)->LOJA
            Z41->Z41_DESC    :=  (_cAlias)->DESCRICAO
            Z41->Z41_FAT_A   :=  (_cAlias)->FAT_A
            Z41->Z41_FAT_B   :=  (_cAlias)->FAT_B
            Z41->Z41_ATING   :=  _nPercFat
         Z41->(Msunlock())

         If oProc <> Nil .And. !_lScheduler
            oProc:cCaption:='Gravando Registro: '+AllTrim(STR(_nConta))
            ProcessMessages()
         EndIf
         
         (_cAlias)->(Dbskip())
      
      EndDo

      (_cAlias)->(Dbclosearea())

   EndIf    

Return _lRet

/*
===============================================================================================================================
Programa----------: Z41DELET
Autor-------------: Jose Gavetti
Data da Criacao---: 24/09/2025
Descrição---------: Deleta os registro do periodo selecionado
Parametros--------: Periodo a ser excluido
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function Z41DELET(_cPeriod)

   Local _cQry     := ""
   Local _nRet     := 0

   Default _cPeriod := ""

   Begin Transaction

      _cQry := "DELETE FROM " + RetSqlName("Z41") + " "
      _cQry += "WHERE Z41_FILIAL = '" + xFilial("Z41") + "' "
      _cQry += "  AND Z41_PERIOD = '" + _cPeriod + "' "

      _nRet := TCSqlExec(_cQry)

		If _nRet != 0 .and. !_lScheduler
			MsgStop("Erro na execução da query: "+TcSqlError(), "Atenção")
			DisarmTransaction()
		EndIf
      
	End Transaction

Return
