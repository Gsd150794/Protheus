/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Alex Wallauer |20/01/2022| Chamado 38900. Troca do pergunte() para o ParamBox()
Alex Wallauer |04/07/2023| Chamado 44373. Vanderlei. Retirado o 3 parametro e feito o tratamento para o campo ACY_I_BOLE.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: FA060QRY()
Autor-------------: Alex Wallauer
Data da Criacao---: 09/01/2019 
Descrição---------: PE com o objetivo de criar filtros no momento da geracao do Bordero de contas a receber CHAMADO: 27385
Parametros--------: Nenhum
Retorno-----------: WHERE DA SELECT DO FILTRO
===============================================================================================================================
*/
User Function FA060QRY()

Local _cQueryADD:=""
Local _aParRet :={}
Local _aParAux :={}  , nI
MV_PAR01:=Space(490)
MV_PAR02:="3-Ambos"

aAdd( _aParAux , { 1 ,"Redes"              , MV_PAR01, "@S99"    , ""      ,"REDE50"  , "" , 110 , .F. } ) 
aAdd( _aParAux , { 2 ,"Cliente Imp. boleto", MV_PAR02, {"1-Sim  ","2-Nao  ","3-Ambos"}, 060,".T.", .F. } )

For nI := 1 To Len( _aParAux )
    aAdd( _aParRet , _aParAux[nI][03] )
Next    
          //aParametros, cTitle                                , @aRet    ,[bOk], [ aButtons ] [ lCentered ] [ nPosX ] [ nPosy ] [ oDlgWizard ] [ cLoad ] [ lCanSave ] [ lUserSave ] 
If !ParamBox( _aParAux , "Selecione os filtros" , @_aParRet,     , /*aButtons*/,/*lCentered*/,/*nPosX*/,/*nPosy*/,/*oDlgWizard*/,/*cLoad*/,.T.         ,.T.          )
	MV_PAR01 := " "	// REDE
	MV_PAR02 := 3	// JA GEROU BOLETO
	//MV_PAR03 := " " // EXceto Rede
Else
    MV_PAR02:=Val(MV_PAR02)
EndIf

If !Empty(AllTrim(MV_PAR01))
	_cQueryADD += " E1_I_GPRVE IN " + FormatIn(AllTrim(MV_PAR01),";")
EndIf

If !Empty(_cQueryADD) .And. MV_PAR02 < 3
	_cQueryADD += " AND "
EndIf

If MV_PAR02 == 1 // SIM
	_cQueryADD += " EXISTS (SELECT 1 FROM SA1010  SA1     "
	_cQueryADD += "                  JOIN ACY010  ACY ON ACY.ACY_GRPVEN = SA1.A1_GRPVEN  AND ACY_I_BOLE  <> 'N' AND ACY.D_E_L_E_T_  = ' '     "
	_cQueryADD += "                  WHERE A1_I_IBOLE <> 'N' AND SA1.D_E_L_E_T_  = ' ' AND SE1.E1_CLIENTE = A1_COD AND SE1.E1_LOJA = A1_LOJA )     "
	_cQueryADD += "AND NVL((SELECT E4_I_IBOLE FROM SE4010 SE4, SF2010  SF2     " 
	_cQueryADD += " WHERE SF2.D_E_L_E_T_ = ' ' AND SE4.D_E_L_E_T_ = ' '     " 
	_cQueryADD += "   AND SF2.F2_COND    = SE4.E4_CODIGO      "
	_cQueryADD += "   AND SF2.F2_FILIAL  = SE1.E1_FILIAL     "
	_cQueryADD += "   AND SF2.F2_DOC     = SE1.E1_NUM     "
	_cQueryADD += "   AND (SF2.F2_SERIE  = SE1.E1_PREFIXO OR SE1.E1_PREFIXO = 'R' OR SE1.E1_PREFIXO = 'MAN')     "
	_cQueryADD += "   AND SF2.F2_CLIENTE = SE1.E1_CLIENTE     "
	_cQueryADD += "   AND SF2.F2_LOJA    = SE1.E1_LOJA),'S') <> 'N'     "
ElseIf MV_PAR02 == 2 //NAO
	_cQueryADD += " (EXISTS (SELECT 1 FROM SA1010 SA1 "
	_cQueryADD += "                   WHERE A1_I_IBOLE = 'N' AND SA1.D_E_L_E_T_  = ' ' AND SE1.E1_CLIENTE = A1_COD AND SE1.E1_LOJA = A1_LOJA )  " 
	_cQueryADD += "  OR "
	_cQueryADD += "  EXISTS (SELECT 1 FROM ACY010 ACY  
	_cQueryADD += "                   WHERE ACY_I_BOLE = 'N' AND ACY.D_E_L_E_T_  = ' ' AND SE1.E1_I_GPRVE = ACY.ACY_GRPVEN) "
	_cQueryADD += "  OR  "
	_cQueryADD += "NVL((SELECT E4_I_IBOLE FROM SE4010 SE4, SF2010  SF2  " 
	_cQueryADD += " WHERE SF2.D_E_L_E_T_ = ' ' AND SE4.D_E_L_E_T_ = ' '  " 
	_cQueryADD += "   AND SF2.F2_COND    = SE4.E4_CODIGO   "
	_cQueryADD += "   AND SF2.F2_FILIAL  = SE1.E1_FILIAL  "
	_cQueryADD += "   AND SF2.F2_DOC     = SE1.E1_NUM  "
	_cQueryADD += "   AND (SF2.F2_SERIE  = SE1.E1_PREFIXO OR SE1.E1_PREFIXO = 'R' OR SE1.E1_PREFIXO = 'MAN')  "
	_cQueryADD += "   AND SF2.F2_CLIENTE = SE1.E1_CLIENTE  "
	_cQueryADD += "   AND SF2.F2_LOJA    = SE1.E1_LOJA),'S') = 'N' )  "
 EndIf

//If !Empty(_cQueryADD) .And. !Empty(AllTrim(MV_PAR03))
//	_cQueryADD += " AND "
//EndIf
//If !Empty(AllTrim(MV_PAR03))
//	_cQueryADD += " E1_I_GPRVE NOT IN " + FormatIn(AllTrim(MV_PAR03),";")
//EndIf

If Empty(_cQueryADD)
   Return//Tem que devolver NIL pq senão o padrão adiciona o codigo  cQuery += " AND (" + cQueryADD + ")" E DÁ ERRO 
Else
   Return _cQueryADD
EndIf   
