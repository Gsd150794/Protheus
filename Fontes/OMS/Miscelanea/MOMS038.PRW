/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Julio Paz     |26/03/2021| Chamado 35936. Correção na exibição do Status do Historico das tabelas de preços.
Lucas Borges  |09/10/2024| Chamado 48465. Retirada manipulação do SX1
===============================================================================================================================
*/

#Include "TOTVS.ch"
#Include "FWMVCDEF.CH"
#Include "TBICONN.CH"

/*
===============================================================================================================================
Programa----------: MOMS038
Autor-------------: Josué Danich Prestes
Data da Criacao---: 19/03/2018
Descrição---------: Histórico de alterações nas tabelas de preço - Chamado 24295 
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MOMS038()

If Pergunte( 'MOMS038' )
	//Log de acesso
	u_itlogacs()
	FWMsgRun( ,{|| _aAlias := MOMS038P() } , 'Aguarde!' , 'Verificando os registros...' )
EndIf

Return

/*
===============================================================================================================================
Programa----------: MOMS038P
Autor-------------: Josué Danich Prestes
Data da Criacao---: 19/03/2018
Descrição---------: Processamento do Histórico de alterações nas tabelas de preço 
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MOMS038P()

Local _cQuery := ''
Local calias  := GetNextAlias()
Local _alista := {}
Local _cStatus := ""

If Empty(MV_PAR01) .And. Empty(MV_PAR02)

  MV_PAR01 := "   "
  MV_PAR02 := "ZZZ"

EndIf

If Empty(MV_PAR03) .And. Empty(MV_PAR04)

  MV_PAR03 := Space(15)
  MV_PAR04 := "ZZZZZZZZZZZZZZZ"

EndIf


//-- Busca histórico na ZGS--//
_cQuery := " SELECT "
_cQuery += "    ZGS_FILIAL,ZGS_DATA,ZGS_HORA,ZGS_USER,ZGS_MODULO,ZGS_CODTAB,ZGS_DATDE,ZGS_ODATDE,ZGS_HORADE,ZGS_OHORAD,ZGS_DATATE,ZGS_ODATAT,ZGS_HORATE,ZGS_OHORAT,"
_cQuery += "    ZGS_CONDPG,ZGS_OCONDP,ZGS_TPHORA,ZGS_OTPHOR,ZGS_ATIVO ,ZGS_OATIVO,ZGS_CODPRO,ZGS_OCODPR,ZGS_GRUPO,ZGS_OGRUPO,ZGS_PRCBAS,ZGS_OPRCBA,ZGS_PRCVEN,"
_cQuery += "    ZGS_OPRCVE,ZGS_I_PRCA,ZGS_I_OPRC,ZGS_PRCMAX,ZGS_OPRCMA,ZGS_I_PRMP,ZGS_I_OPRM,ZGS_I_PTBN,ZGS_I_OPTB,ZGS_I_VIGI,ZGS_I_OVII,ZGS_I_VIGF,ZGS_I_OVIF,ZGS_ITEM,ZGS_STATUS"
_cQuery += " FROM "+ RetSqlName("ZGS") +" ZGS "
_cQuery += " WHERE "
_cQuery += "     ZGS.ZGS_CODTAB	>= '"+ MV_PAR01 +"' "
_cQuery += " AND    ZGS.ZGS_CODTAB	<= '"+ MV_PAR02 +"' "
_cQuery += " AND    (ZGS.ZGS_CODPRO	>= '"+ MV_PAR03 +"' OR  ZGS.ZGS_OCODPR	>= '"+ MV_PAR03 +"') "
_cQuery += " AND    (ZGS.ZGS_CODPRO	<= '"+ MV_PAR04 +"' OR  ZGS.ZGS_OCODPR	<= '"+ MV_PAR04 +"') "

If !Empty(DToS(MV_PAR05)) .And. !Empty(DToS(MV_PAR06))

	_cQuery += " AND	ZGS.ZGS_DATA	>= '"+ DToS(MV_PAR05) +"' "
	_cQuery += " AND	ZGS.ZGS_DATA	<= '"+ DToS(MV_PAR06) +"' "
	
Else

	MV_PAR05 := SToD("20010101")
	MV_PAR06 := SToD("20300101")

EndIf

_cQuery += " AND ZGS.D_E_L_E_T_	= ' ' "
_cQuery += " ORDER BY ZGS_CODTAB,ZGS_ITEM,ZGS_DATA,ZGS_HORA"

If Select(cAlias) > 0
	(cAlias)->( DBCloseArea() )
EndIf

DBUseArea( .T. , "TOPCONN" , TcGenQry(,,_cQuery) , cAlias , .T. , .F. )

DBSelectArea(cAlias)
(cAlias)->( DBGoTop() )

While  (cAlias)->(!Eof()) 

   If (cAlias)->ZGS_STATUS == "I"
      _cStatus := "INCLUSÃO"
   ElseIf (cAlias)->ZGS_STATUS == "A"
      _cStatus := "ALTERAÇÃO"
   ElseIf (cAlias)->ZGS_STATUS == "X"
      _cStatus := "EXCLUSÃO"
   Else 
      _cStatus := ""
   EndIf 

	aAdd(_alista,{  SToD((cAlias)->ZGS_DATA),;
					AllTrim((cAlias)->ZGS_HORA),;
					AllTrim((cAlias)->ZGS_USER),;
					(cAlias)->ZGS_CODTAB,;
					AllTrim((cAlias)->ZGS_ITEM),;
					SToD((cAlias)->ZGS_DATDE),;
					SToD((cAlias)->ZGS_ODATDE),;
					AllTrim((cAlias)->ZGS_HORADE),;
					AllTrim((cAlias)->ZGS_OHORAD),;
					SToD((cAlias)->ZGS_DATATE),;
					SToD((cAlias)->ZGS_ODATAT),;
					AllTrim((cAlias)->ZGS_HORATE),;
					AllTrim((cAlias)->ZGS_OHORAT),;
					AllTrim((cAlias)->ZGS_CONDPG),;
					AllTrim((cAlias)->ZGS_OCONDP),;
					If(AllTrim((cAlias)->ZGS_TPHORA)=='1',"UNICO","RECURSIVO"),;
					If(AllTrim((cAlias)->ZGS_OTPHOR)=='1',"UNICO","RECURSIVO"),;
					If(AllTrim((cAlias)->ZGS_ATIVO)=='1',"SIM","NAO"),;
					If(AllTrim((cAlias)->ZGS_OATIVO)=='1',"SIM","NAO"),;
					AllTrim((cAlias)->ZGS_CODPRO),;
					AllTrim((cAlias)->ZGS_OCODPR ),;
					AllTrim((cAlias)->ZGS_GRUPO ),;
					AllTrim((cAlias)->ZGS_OGRUPO ),;
					transform((cAlias)->ZGS_PRCBAS, "@E 999,999,999.99" ),;
					transform((cAlias)->ZGS_OPRCBA, "@E 999,999,999.99" ),;
					transform((cAlias)->ZGS_PRCVEN, "@E 999,999,999.99" ),;
					transform((cAlias)->ZGS_OPRCVE, "@E 999,999,999.99" ),;
					transform((cAlias)->ZGS_I_PRCA, "@E 999,999,999.99" ),;
					transform((cAlias)->ZGS_I_OPRC, "@E 999,999,999.99" ),;
					transform((cAlias)->ZGS_PRCMAX, "@E 999,999,999.99" ),;
					transform((cAlias)->ZGS_OPRCMA, "@E 999,999,999.99" ),;
					transform((cAlias)->ZGS_I_PRMP, "@E 999,999,999.99" ),;
					transform((cAlias)->ZGS_I_OPRM, "@E 999,999,999.99" ),;
					transform((cAlias)->ZGS_I_PTBN, "@E 999,999,999.99" ),;
					transform((cAlias)->ZGS_I_OPTB, "@E 999,999,999.99" ),;
					SToD((cAlias)->ZGS_I_VIGI ),;
					SToD((cAlias)->ZGS_I_OVII ),;
					SToD((cAlias)->ZGS_I_VIGF ),;
					SToD((cAlias)->ZGS_I_OVIF ),;
			        _cStatus }) // 		If(!Empty((cAlias)->ZGS_STATUS),"DELETADO","ATIVO")
              
	(cAlias)->( DBSkip() )
	
EndDo

_ahead := {	"Data",;
			"Hora",;
			"Usuário",;
			"Tabela",;
			"Item",;
			"Dt de",;
			"Dt De ant",;
			"Hora de",;
			"Hora de ant",;
			"Dt Ate",;
			"Dt Ate Ant",;
			"Hora ate",;
			"Hora ate Ant",;
			"Cd pgto",;
			"Cd pgto Ant",;
			"Tipo hora",;
			"Tipo hora ant",;
			"Ativo",;
			"Ativo ant",;
			"Produto",;
			"Produto ant",;
			"Grupo",;
			"Grupo ant",;
			"Prc Bas",;
			"Prc Bas Ant",;
			"Prc Venda",;
			"Prc Venda Ant",;
			"Prc Max",;
			"Prc Mx Ant",;
			"Prc Max Pad",;
			"Prc Max Pad Ant",;
			"Min portal",;
			"Min portal Ant",;
			"Tab Negoc",;
			"Tab Negoc Ant",;
			"Vig Neg Ini",;
			"Vig Neg Ini Ant",;
			"Vig Neg Fin",;
			"Vig Neg Fin Ant",;
			"Status"	}

If Len(_alista) > 0

 U_ITListBox( "Histórico",	_ahead,	 _alista , .F. , 1,"Histórico para tabelas/produtos " + AllTrim(MV_PAR01)+"/"+ AllTrim(MV_PAR03) + " até " + AllTrim(MV_PAR02) +"/"+;
  			AllTrim(MV_PAR04) +	" da data " + DToC(MV_PAR05) + " até " + DToC(MV_PAR06) + ":"  )

Else

	U_ITMsg("Não foram localizados históricos com os parâmetros indicados","Atenção",,1)
	
EndIf
	
Return
