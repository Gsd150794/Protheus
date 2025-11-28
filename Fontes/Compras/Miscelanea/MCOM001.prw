/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |13/10/2024| Chamado 48465. Retirada da função de conout
Lucas Borges  |23/07/2025| Chamado 51340. Trocado e-mail padrão para sistema@italac.com.br
Lucas Borges  |17/09/2025| Chamado 50617. Migração dos parâmetros da ZP1 para SX6
===============================================================================================================================
*/

#Include "tbiconn.ch"
#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: MCOM01GR()
Autor-------------: Alex Wallauer
Data da Criacao---: 15/02/2018
Descrição---------: Rotina responsavel pelo envio do relatório de Pedidos Liberados da semna por e-mail 
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MCOM01GR()

U_MCOM001(.T.)

Return

/*
===============================================================================================================================
Programa----------: MCOM001
Autor-------------: Darcio Ribeiro Sporl
Data da Criacao---: 29/02/2016
Descrição---------: Rotina responsavel pelo envio do relatório de Pedidos Liberados do dia anterior por e-mail 
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MCOM001(lPorGrupo)

Local _aTables	:= {"SCR","SC7","ZZL"}
Local cPerg		:= "MCOM001"
Local oproc      
Default lPorGrupo := .F.

If ValType(lPorGrupo) <> "L"//Caso venha uma array 
   _lPorGrupo := .F.
Else
   _lPorGrupo := lPorGrupo
EndIf

Private lAmbiente	:= .F.
Private _lCriaAmb	:= .F.

//=============================================================
// Verifica a necessidade de criar um ambiente, caso nao esteja
// criado anteriormente um ambiente, pois ocorrera erro
//=============================================================
If Select("SX3") <= 0
	_lCriaAmb:= .T.
EndIf

If _lCriaAmb

	//=====================
	// Nao consome licensas
	//=====================
	RPCSetType(3)

	//===========================================
	// Seta o ambiente com a empresa 01 filial 01
	//===========================================
	RpcSetEnv("01","01",,,,"SCHEDULE_PC_LIBERADOS",_aTables)

    If _lPorGrupo
       MV_PAR01:=Date()-7
       MV_PAR02:=Date() 
    Else
       MV_PAR01:=Date()-1
       MV_PAR02:=Date()-1
    EndIf
	//========================================================================================
	// Mensagem que ficara armazenada no arquivo totvsconsole.log para posterior monitoramento
	//======================================================================================== 
	FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00101"/*cMsgId*/, "MCOM00101 - Gerando envio da Lista de Pedidos Aprovados na data: " + DToC(MV_PAR01) + " ate "+DToC(MV_PAR02)+" por e-mail."/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
    
Else
	lAmbiente := .T.
EndIf

Private _cGrupos    := AllTrim(SuperGetMV("IT_MC01GRC",.F.,"000090"))
Private _cEmailDir  := AllTrim(SuperGetMV("IT_MCO1EMD" ,.F.,"sistema@italac.com.br"))
Private _cTitGrupo  := ""
If _lPorGrupo
   _cTitGrupo :=" - GESTAO GERENCIA"
EndIf   


If lAmbiente
	If !Pergunte(cPerg,.T.)
	     Return
	EndIf
EndIf

//Executa relatório
If lAmbiente

	FWMsgRun(,{|oproc| MCOM001P(oproc)},"Aguarde...","Processando relatório...")

Else

	FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00102"/*cMsgId*/, "MCOM00102 - Iniciando relatório de pedidos liberados..."/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
	MCOM001P(oproc)
	FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00103"/*cMsgId*/, "MCOM00103 - Relatório de pedidos liberados executado com sucesso."/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)

EndIf

Return


/*
===============================================================================================================================
Programa----------: MCOM001P
Autor-------------: Josué Danich Prestes
Data da Criacao---: 29/02/2016
Descrição---------: Processamento do relatório
Parametros--------: oproc - objeto da barra de processamento
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MCOM001P(oproc)

Local _cQryR03		:= "" , A
Local _cQryR04		:= ""
Local _cHtml03		:= ""
Local _cHtml04		:= ""
Local _cQryR3		:= ""
Local _cQryR4		:= ""
Local _cQryZZL		:= ""
Local cEmail		:= ""
Local lWFHTML		:= .T.
Local _cHtml		:= ""
Local _aConfig		:= {}
Local _cEmlLog		:= ""
Local lEmail		:= .F.
Local nTotal		:= 0
Local nCount		:= 0
Local dDataLib		:= Ctod("//")
Local cHrApr		:= ""
Local cObs			:= ""
Local cUsuario		:= ""
Local cStatus		:= ""
Local cCmpDi		:= ""
Local cUrgen		:= ""
Local cFornece		:= ""
Local cLoja			:= ""
Local cNreduz		:= ""
Local dDatPrf		:= Ctod("//")
Local _cFilial		:= ""
Local cNumPc		:= ""
Local lImprime		:= .F.
Local lLibera		:= .T.
Local lRejeita		:= .T.

//================================
//Guardo valor padrão do parâmetro
//================================
lWFHTML	:= GetMv("MV_WFHTML")

//=========================================================
//Altero o valor do parâmetro para enviar o modelo em anexo
//=========================================================
PutMV("MV_WFHTML",.F.)

_aConfig  := U_ITCFGEML('')
cGetAssun := "Relatório Pedidos Liberados / Rejeitados no Período de " + DToC(MV_PAR01) + " até " + DToC(MV_PAR02)+_cTitGrupo

_cHtml += '<html>'
_cHtml += '<head>'
_cHtml += '<title>Pedidos Liberados/Rejeitados</title>'
_cHtml += '</head>'
_cHtml += '<style Type="text/css"><!--'
_cHtml += 'table.bordasimples { border-collapse: collapse; }'
_cHtml += 'table.bordasimples tr td { border:1px solid #777777; }'
_cHtml += 'td.grupos	{ font-family:VERDANA; font-size:20px; V-align:middle; background-color: #C6E2FF; color:#000080; }'
_cHtml += 'td.titulos	{ font-family:VERDANA; font-size:12px; V-align:middle; margin-right: 15px; margin-left: 15px; background-color: #EEDD82; }'
_cHtml += 'td.texto	{ font-family:VERDANA; font-size:12px; V-align:middle; margin-right: 15px; margin-left: 15px; }'
_cHtml += 'td.itens	{ font-family:VERDANA; font-size:12px; V-align:middle; margin-right: 15px; margin-left: 15px; background-color: #DDDDDD; }'
_cHtml += 'td.totais	{ font-family:VERDANA; font-size:12px; V-align:middle; margin-right: 15px; margin-left: 15px; background-color: #7f99b2; color:#FFFFFF; }'
_cHtml += '--></style>'
 
_cHtml += '<body bgcolor="#FFFFFF">'
_cHtml += '<center>'

If lAmbiente

	oproc:cCaption := ("1/3 - Carregando liberações...")
	ProcessMessages()
	
EndIf


//===========================================
//Query que lista os PC's que foram liberados
//===========================================
_cQryR03 := "SELECT CR_FILIAL, CR_NUM, MAX(CR_NIVEL) CR_NIVEL " 
_cQryR03 += "FROM " + RetSqlName("SCR") + " SCR "
_cQryR03 += "WHERE CR_STATUS = '03' "
_cQryR03 += "  AND CR_TIPO = 'PC' "
_cQryR03 += "  AND CR_DATALIB BETWEEN '" + DToS(MV_PAR01) + "' AND '" + DToS(MV_PAR02) + "' "
If _lPorGrupo
  _cQryR03 += "  AND CR_GRUPO IN " + FormatIn(_cGrupos,";")
EndIf    

_cQryR03 += " AND CR_NIVEL = (SELECT MAX(CR_NIVEL) FROM " + RetSqlName("SCR") + " SCR2 "+ " WHERE SCR2.D_E_L_E_T_ = ' ' AND SCR2.CR_TIPO = 'PC'  AND SCR2.CR_FILIAL = SCR.CR_FILIAL AND SCR2.CR_NUM = SCR.CR_NUM) "

_cQryR03 += "  AND D_E_L_E_T_ = ' ' "
_cQryR03 += "GROUP BY CR_FILIAL, CR_NUM "
_cQryR03 += "ORDER BY CR_FILIAL, CR_NUM "

FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00104"/*cMsgId*/, "MCOM00104 - SELECT 1: "+_cQryR03/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)

dbUseArea( .T. , "TOPCONN" , TcGenQry(,, _cQryR03 ) , "TRBR03" , .T., .F. )

DBSelectArea("TRBR03")
TRBR03->(DBGoTop())

If TRBR03->(Eof())
	lLibera := .F.
Else

	While !TRBR03->(Eof())
	
		nCount := 0
		nTotal := 0

        If lAmbiente
        	oproc:cCaption := ("1/3 - Lendo PV: "+TRBR03->CR_FILIAL +"-"+TRBR03->CR_NUM)
        	ProcessMessages()
        EndIf
	
		//=============================================================
		//Posiciono no pedido para fazer a somatória do total do pedido
		//=============================================================
		DBSelectArea("SC7")
		DBSetOrder(1)
		If DBSeek( TRBR03->CR_FILIAL + SubStr(TRBR03->CR_NUM,1,6) )
	
			While !SC7->(Eof()) .And. SC7->C7_FILIAL == TRBR03->CR_FILIAL .And. SC7->C7_NUM == SubStr(TRBR03->CR_NUM,1,6)
				If SC7->C7_CONAPRO == "L"
					lImprime	:= .T.
					lEmail		:= .T.
					nCount++
					If nCount == 1
						//======================================================================================
						//Query que lista apenas o último nível de aprovação, para impressão dos dados no e-mail
						//======================================================================================
						_cQryR3 := "SELECT R_E_C_N_O_ AS REC "
						_cQryR3 += "FROM " + RetSqlName("SCR") + " "
						_cQryR3 += "WHERE CR_FILIAL = '" + TRBR03->CR_FILIAL + "' "
						_cQryR3 += "  AND CR_TIPO = 'PC' "
						_cQryR3 += "  AND SubStr(CR_NUM,1,6) = '" + SubStr(TRBR03->CR_NUM,1,6) + "' "
						_cQryR3 += "  AND CR_NIVEL = '" + TRBR03->CR_NIVEL + "' "
						_cQryR3 += "  AND D_E_L_E_T_ = ' ' "
		
						dbUseArea( .T. , "TOPCONN" , TcGenQry(,, _cQryR3 ) , "TRBR3" , .T., .F. )
		
						DBSelectArea("TRBR3")
						TRBR3->(DBGoTop())
		
						SCR->(DBGoTo(TRBR3->REC))
		
						dDataLib	:= DToS(SCR->CR_DATALIB)
						cHrApr		:= SCR->CR_I_HRAPR
						cObs		:= AllTrim(SCR->CR_OBS)
                    	If !_lPorGrupo
						   cObs		+= " ("+SCR->CR_GRUPO+")"
						EndIf
						cUsuario	:= SCR->CR_USER
						cStatus		:= "Aprovado"
						If SC7->C7_I_CMPDI == "S"
							cCmpDi	:= "Sim"
						Else
							cCmpDi	:= "Não"
						EndIf
						If SC7->C7_I_URGEN == "S"
							cUrgen	:= "Sim"
						ElseIf SC7->C7_I_URGEN == "F"
							cUrgen	:= "NF"
						Else
							cUrgen	:= "Não"
						EndIf
						_cFilial	:= SC7->C7_FILIAL + " - " + AllTrim(FWFilialName(cEmpAnt, SC7->C7_FILIAL))
						cNumPc		:= SC7->C7_NUM
						cFornece	:= SC7->C7_FORNECE
						cLoja		:= SC7->C7_LOJA
						cNreduz		:= Posicione("SA2",1,xFilial("SA2") + cFornece + cLoja, "A2_NREDUZ")
						dDatPrf		:= SC7->C7_DATPRF
		
						DBSelectArea("TRBR3")
						TRBR3->(DBCloseArea())
					EndIf
					nTotal += SC7->C7_TOTAL
				EndIf
				SC7->(DBSkip())
			End
	
			If lImprime
				_cHtml03 += '	<tr>'+CRLF
				_cHtml03 += '		<td valign="top" height="23" class="itens">' + _cFilial + '</td>'
				_cHtml03 += '		<td valign="top" height="23" class="itens">' + cNumPc + '</td>'
				_cHtml03 += '		<td valign="top" height="23" class="itens">' + AllTrim(cNreduz) + '</td>'
				_cHtml03 += '		<td align="right" valign="top" height="23" class="itens">' + Transform(nTotal, PesqPict("SC7","C7_TOTAL")) + '</td>'
				_cHtml03 += '		<td valign="top" height="23" class="itens"><center>' + cCmpDi + '</center></td>'
				_cHtml03 += '		<td valign="top" height="23" class="itens"><center>' + cUrgen + '</center></td>'
				_cHtml03 += '		<td valign="top" height="23" class="itens">' + AllTrim(cObs) + '</td>'
				If !_lPorGrupo
				   _cHtml03 += '	<td valign="top" height="23" class="itens">' + SubStr(AllTrim(UsrRetName(cUsuario)),1,Len(AllTrim(UsrRetName(cUsuario)))-1) + '</td>'
				EndIf   
				_cHtml03 += '		<td valign="top" height="23" class="itens"><center>' + DToC(SToD(dDataLib)) + " - " + cHrApr + '</center></td>'+CRLF
				_cHtml03 += '		<td valign="top" height="23" class="itens"><center>' + DToC(dDatPrf) + '</center></td>'+CRLF
				_cHtml03 += '	</tr>'+CRLF
				lImprime := .F.
			EndIf
	
		EndIf
	
		TRBR03->(DBSkip())
	End

	_cHtml += '<table width="100%" cellspacing="0" cellpadding="2" border="0">'+CRLF
	_cHtml += '	<tr>'+CRLF
	_cHtml += '		<td width="02%" class="grupos">'+CRLF
	_cHtml += '			<center><img src="http://www.italac.com.br/wp-content/themes/italac/assets/images/logo.svg" width="100px" height="030px"></center>'+CRLF
	_cHtml += '		</td>'
	_cHtml += '		<td width="98%" class="grupos"><center>Relação de Pedidos Liberados no Período de ' + DToC(MV_PAR01) + ' até ' + DToC(MV_PAR02) +_cTitGrupo+ '</center></td>'
	_cHtml += '	</tr>'+CRLF

	If _lPorGrupo
		_cHtml += '</table>'+CRLF
		_cHtml += '<br>	'+CRLF		
		_cHtml += '<table width="40%" border="0" CellSpacing="2" CellPadding="0">'+CRLF
		_cHtml += '	<tr>'+CRLF
		_cHtml += '		<td align="center" height="15" class="totais">TABELA DE APROVADORES ('+_cGrupos+')</center></td>'+CRLF
		_cHtml += '	</tr>'+CRLF
		_cHtml += '</table>'+CRLF
		_cHtml += '<table width="40%" border="0" CellSpacing="2" CellPadding="0">'+CRLF
		_aProv:=MCOM01Grupo(_cGrupos)
		For A := 1 To Len(_aProv)
			_cHtml += '	<tr>'+CRLF
			_cHtml += '		<td valign="top" height="15" class="itens">' + _aProv[A,1] + '</td>'+CRLF
			_cHtml += '		<td valign="top" height="15" class="itens">' + _aProv[A,2] + '</td>'+CRLF
			_cHtml += '	</tr>'+CRLF
		Next
	    _cHtml += '</table>'+CRLF
		_cHtml += '<br>	'+CRLF		
    Else
	    _cHtml += '</table>'+CRLF
	EndIf

	_cHtml += '<table width="100%" border="0" CellSpacing="2" CellPadding="0">'+CRLF
	_cHtml += '	<tr>'+CRLF
	_cHtml += '		<td align="center" height="23" class="totais">Filial</td>'+CRLF
	_cHtml += '		<td align="center" height="23" class="totais">Pedido</td>'+CRLF
	_cHtml += '		<td align="center" height="23" class="totais">Fornecedor</td>'+CRLF
	_cHtml += '		<td align="center" height="23" class="totais">Valor Pedido</td>'+CRLF
	_cHtml += '		<td align="center" height="23" class="totais">Compra<br>Direta</td>'+CRLF
	_cHtml += '		<td align="center" height="23" class="totais">Urgente</td>'+CRLF
	_cHtml += '		<td align="center" height="23" class="totais">Observação</td>'+CRLF
    If !_lPorGrupo
	    _cHtml += '	<td align="center" height="23" class="totais">Aprovador</td>'+CRLF
    EndIf
	_cHtml += '		<td align="center" height="23" class="totais">Data Liberação</td>'+CRLF
	_cHtml += '		<td align="center" height="23" class="totais">Data Entrega</td>'+CRLF
	_cHtml += '	</tr>'+CRLF

	_cHtml03 += '	</table>'
	_cHtml03 += '	<br><br><br>'
	
	_cHtml += _cHtml03

EndIf

If lAmbiente

	oproc:cCaption := ("2/3 - Carregando rejeições...")
	ProcessMessages()
	
EndIf


//============================================
//Query que lista os PC's que foram Rejeitados
//============================================
_cQryR04 := "SELECT CR_FILIAL, CR_NUM, MAX(CR_NIVEL) CR_NIVEL " 
_cQryR04 += "FROM " + RetSqlName("SCR") + " SCR "
_cQryR04 += "WHERE CR_STATUS = '04' "
_cQryR03 += "  AND CR_TIPO = 'PC' "
//If lAmbiente
	_cQryR04 += "  AND CR_DATALIB BETWEEN '" + DToS(MV_PAR01) + "' AND '" + DToS(MV_PAR02) + "' "
//Else
//	_cQryR04 += "  AND CR_DATALIB = '" + DToS(Date()-1) + "' "
//EndIf
If _lPorGrupo
   _cQryR04 += "  AND CR_GRUPO IN " + FormatIn(_cGrupos,";")
EndIf    
_cQryR04 += " AND CR_NIVEL = (SELECT MAX(CR_NIVEL) FROM " + RetSqlName("SCR") + " SCR2 "+ " WHERE SCR2.D_E_L_E_T_ = ' ' AND SCR2.CR_TIPO = 'PC' AND SCR2.CR_FILIAL = SCR.CR_FILIAL AND SCR2.CR_NUM = SCR.CR_NUM) "
_cQryR04 += "  AND D_E_L_E_T_ = ' ' "
_cQryR04 += "GROUP BY CR_FILIAL, CR_NUM "
_cQryR04 += "ORDER BY CR_FILIAL, CR_NUM "

FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00105"/*cMsgId*/, "MCOM00105 - SELECT 2: "+_cQryR04/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)

dbUseArea( .T. , "TOPCONN" , TcGenQry(,, _cQryR04 ) , "TRBR04" , .T., .F. )

DBSelectArea("TRBR04")
TRBR04->(DBGoTop())

If TRBR04->(Eof())
	lRejeita := .F.
Else

	While !TRBR04->(Eof())
	
		lEmail := .T.
	
		nCount := 0
		nTotal := 0
        If lAmbiente
        	oproc:cCaption := ("2/3 - Lendo PV: "+TRBR04->CR_FILIAL +"-"+TRBR04->CR_NUM)
        	ProcessMessages()
        EndIf
	
		//=============================================================
		//Posiciono no pedido para fazer a somatória do total do pedido
		//=============================================================
		DBSelectArea("SC7")
		DBSetOrder(1)
		If DBSeek( TRBR04->CR_FILIAL + SubStr(TRBR04->CR_NUM,1,6) )
	
			While !SC7->(Eof()) .And. SC7->C7_FILIAL == TRBR04->CR_FILIAL .And. SC7->C7_NUM == SubStr(TRBR04->CR_NUM,1,6)
				nCount++
				If nCount == 1
					//======================================================================================
					//Query que lista apenas o último nível de aprovação, para impressão dos dados no e-mail
					//======================================================================================
					_cQryR4 := "SELECT R_E_C_N_O_ AS REC "
					_cQryR4 += "FROM " + RetSqlName("SCR") + " "
					_cQryR4 += "WHERE CR_FILIAL = '" + TRBR04->CR_FILIAL + "' "
					_cQryR4 += "  AND CR_TIPO = 'PC' "
					_cQryR4 += "  AND SubStr(CR_NUM,1,6) = '" + SubStr(TRBR04->CR_NUM,1,6) + "' "
					_cQryR4 += "  AND CR_NIVEL = '" + TRBR04->CR_NIVEL + "' "
					_cQryR4 += "  AND D_E_L_E_T_ = ' ' "
		
					dbUseArea( .T. , "TOPCONN" , TcGenQry(,, _cQryR4 ) , "TRBR4" , .T., .F. )
		
					DBSelectArea("TRBR4")
					TRBR4->(DBGoTop())
					
					SCR->(DBGoTo(TRBR4->REC))
		
					dDataLib	:= DToS(SCR->CR_DATALIB)
					cHrApr		:= SCR->CR_I_HRAPR
					cObs		:= AllTrim(SC7->C7_I_OBSAP)
                   	If !_lPorGrupo
					   cObs		+= " ("+SCR->CR_GRUPO+")"
					EndIf
					cUsuario	:= SCR->CR_USER
					cStatus		:= "Rejeitado"
					If SC7->C7_I_CMPDI == "S"
						cCmpDi	:= "Sim"
					Else
						cCmpDi	:= "Não"
					EndIf
					If SC7->C7_I_URGEN == "S"
						cUrgen	:= "Sim"
					ElseIf SC7->C7_I_URGEN == "F"
						cUrgen	:= "NF"
					Else
						cUrgen	:= "Não"
					EndIf
					_cFilial	:= SC7->C7_FILIAL + " - " + AllTrim(FWFilialName(cEmpAnt, SC7->C7_FILIAL))
					cNumPc		:= SC7->C7_NUM
					cFornece	:= SC7->C7_FORNECE
					cLoja		:= SC7->C7_LOJA
					cNreduz		:= Posicione("SA2",1,xFilial("SA2") + cFornece + cLoja, "A2_NREDUZ")
					dDatPrf		:= SC7->C7_DATPRF
		
					DBSelectArea("TRBR4")
					TRBR4->(DBCloseArea())
		
				EndIf
				nTotal += SC7->C7_TOTAL
				SC7->(DBSkip())
			End
	
			_cHtml04 += '	<tr>'
			_cHtml04 += '		<td valign="top" height="23" class="itens">' + _cFilial + '</td>'
			_cHtml04 += '		<td valign="top" height="23" class="itens">' + cNumPc + '</td>'
			_cHtml04 += '		<td valign="top" height="23" class="itens">' + AllTrim(cNreduz) + '</td>'
			_cHtml04 += '		<td align="right" valign="top" height="23" class="itens">' + Transform(nTotal, PesqPict("SC7","C7_TOTAL")) + '</td>'
			_cHtml04 += '		<td valign="top" height="23" class="itens"><center>' + cCmpDi + '</center></td>'
			_cHtml04 += '		<td valign="top" height="23" class="itens"><center>' + cUrgen + '</center></td>'
			_cHtml04 += '		<td valign="top" height="23" class="itens">' + AllTrim(cObs) + '</td>'
			_cHtml04 += '		<td valign="top" height="23" class="itens">' + SubStr(AllTrim(UsrRetName(cUsuario)),1,Len(AllTrim(UsrRetName(cUsuario)))-1) + '</td>'
			_cHtml04 += '		<td valign="top" height="23" class="itens"><center>' + DToC(SToD(dDataLib)) + " - " + cHrApr + '</center></td>'
			_cHtml04 += '	</tr>'
	
		EndIf
	
		TRBR04->(DBSkip())
	End
	
	_cHtml += '<table width="100%" cellspacing="0" cellpadding="2" border="0">'
	_cHtml += '	<tr>'
	_cHtml += '		<td width="02%" class="grupos">'
	_cHtml += '			<center><img src="http://www.italac.com.br/wp-content/themes/italac/assets/images/logo.svg" width="100px" height="030px"></center>'
	_cHtml += '		</td>'
	_cHtml += '		<td width="98%" class="grupos"><center>Relação de Pedidos Rejeitados no Período de ' + DToC(MV_PAR01) + ' até ' + DToC(MV_PAR02) +_cTitGrupo+ '</center></td>'
	_cHtml += '	</tr>'
	_cHtml += '</table>'
	
	_cHtml += '<table width="100%" border="0" CellSpacing="2" CellPadding="0">'
	_cHtml += '	<tr>'
	_cHtml += '		<td align="center" height="23" class="totais">Filial</td>'
	_cHtml += '		<td align="center" height="23" class="totais">Pedido</td>'
	_cHtml += '		<td align="center" height="23" class="totais">Fornecedor</td>'
	_cHtml += '		<td align="center" height="23" class="totais">Valor Pedido</td>'
	_cHtml += '		<td align="center" height="23" class="totais">Compra<br>Direta</td>'
	_cHtml += '		<td align="center" height="23" class="totais">Urgente</td>'
	_cHtml += '		<td align="center" height="23" class="totais">Observação</td>'
	_cHtml += '		<td align="center" height="23" class="totais">Aprovador</td>'
	_cHtml += '		<td align="center" height="23" class="totais">Data Rejeição</td>'
	_cHtml04 += '</table>'

	_cHtml04 += '<br><br><br>'

	_cHtml += _cHtml04

EndIf

_cHtml += '<table>'
_cHtml += '<tr>'
_cHtml += '	<td class="grupos" align="center" colspan="8"><a href="http://www.italac.com.br/">http://www.italac.com.br/</a></td>'
_cHtml += '</tr>'
_cHtml += '<tr>'
_cHtml += '	<td class="grupos" align="center" colspan="8"><font color="red"><u>Esta é uma mensagem automática. Por favor não a responda!</u></font></td>'
_cHtml += '</tr>'
_cHtml += '</table>'

_cHtml += '</center>'
_cHtml += '</body>'
_cHtml += '</html>
_cHtml += '<br><br>'
_cHtml += '<br>Ambiente: '+GetEnvServer()+'<br>'

DBSelectArea("TRBR04")
TRBR04->(DBCloseArea())

DBSelectArea("TRBR03")
TRBR03->(DBCloseArea())

If lAmbiente

	oproc:cCaption := ("3/3 - Enviando emails...")
	ProcessMessages()
	
EndIf


If lAmbiente
	If !lLibera .And. !lRejeita
		U_ITMsg('Não existe nenhum PC Aprovado/Rejeitado no período selecionado.','Atenção',,1)
	Else
		If lEmail
			
			If _lPorGrupo
				
				cEmail :=_cEmailDir
				
			Else
				
				_cQryZZL := "SELECT ZZL_CODUSU, ZZL_USER, ZZL_NOME, ZZL_EMAIL "
				_cQryZZL += "FROM " + RetSqlName("ZZL") + " "
				_cQryZZL += "WHERE ZZL_ADMPC = 'S' "
				_cQryZZL += "  AND D_E_L_E_T_ = ' ' "
				
				dbUseArea( .T. , "TOPCONN" , TcGenQry(,, _cQryZZL ) , "TRBZZL" , .T., .F. )
				
				DBSelectArea("TRBZZL")
				TRBZZL->(DBGoTop())
				
				While !TRBZZL->(Eof())
					cEmail += AllTrim(Lower(TRBZZL->ZZL_EMAIL)) + ","
					TRBZZL->(DBSkip())
				End
				
				cEmail := _cEmailDir//SubStr(cEmail,1,Len(cEmail)-1)
				
				DBSelectArea("TRBZZL")
				TRBZZL->(DBCloseArea())
				
			EndIf
			// Chama a função para envio do e-mail
			U_ITENVMAIL( "", cEmail, "", cEmail, cGetAssun, _cHtml, "", _aConfig[01], _aConfig[02], _aConfig[03], _aConfig[04], _aConfig[05], _aConfig[06], _aConfig[07], @_cEmlLog )
		EndIf
	EndIf
Else
	If !lLibera .And. !lRejeita
		_cHtml := '<html>'
		_cHtml += '<head>'
		_cHtml += '<title>Pedidos Liberados/Rejeitados</title>'
		_cHtml += '</head>'
		_cHtml += '<style Type="text/css"><!--'
		_cHtml += 'table.bordasimples { border-collapse: collapse; }'
		_cHtml += 'table.bordasimples tr td { border:1px solid #777777; }'
		_cHtml += 'td.grupos	{ font-family:VERDANA; font-size:20px; V-align:middle; background-color: #C6E2FF; color:#000080; }'
		_cHtml += 'td.titulos	{ font-family:VERDANA; font-size:12px; V-align:middle; margin-right: 15px; margin-left: 15px; background-color: #EEDD82; }'
		_cHtml += 'td.texto	{ font-family:VERDANA; font-size:12px; V-align:middle; margin-right: 15px; margin-left: 15px; }'
		_cHtml += 'td.itens	{ font-family:VERDANA; font-size:12px; V-align:middle; margin-right: 15px; margin-left: 15px; background-color: #DDDDDD; }'
		_cHtml += 'td.totais	{ font-family:VERDANA; font-size:12px; V-align:middle; margin-right: 15px; margin-left: 15px; background-color: #7f99b2; color:#FFFFFF; }'
		_cHtml += '--></style>'
		 
		_cHtml += '<body bgcolor="#FFFFFF">'
		_cHtml += '<center>'

		_cHtml += '<table>'
		_cHtml += '<tr>'
		_cHtml += '	<td class="grupos" align="center" colspan="8"><a href="http://www.italac.com.br/">http://www.italac.com.br/</a></td>'
		_cHtml += '</tr>'
		_cHtml += '<tr>'
		_cHtml += '	<td class="grupos" align="center" colspan="8"><font color="red"><u>Esta é uma mensagem automática. Por favor não a responda!</u></font></td>'
		_cHtml += '</tr>'
		_cHtml += '</table>'
		
		_cHtml += '</center>'
		_cHtml += '</body>'
		_cHtml += '</html>

		cGetAssun	:= "Não existe PC Liberado / Rejeitado no período de " + DToC(MV_PAR01) + ' até ' + DToC(MV_PAR02)+_cTitGrupo
	EndIf

	If _lPorGrupo
		
		cEmail :=_cEmailDir
		
	Else
		
		_cQryZZL := "SELECT ZZL_CODUSU, ZZL_USER, ZZL_NOME, ZZL_EMAIL "
		_cQryZZL += "FROM " + RetSqlName("ZZL") + " "
		_cQryZZL += "WHERE ZZL_ADMPC = 'S' "
		_cQryZZL += "  AND D_E_L_E_T_ = ' ' "
		
		dbUseArea( .T. , "TOPCONN" , TcGenQry(,, _cQryZZL ) , "TRBZZL" , .T., .F. )
		
		DBSelectArea("TRBZZL")
		TRBZZL->(DBGoTop())
		
		While !TRBZZL->(Eof())
			cEmail += AllTrim(Lower(TRBZZL->ZZL_EMAIL)) + ","
			TRBZZL->(DBSkip())
		End
		
		cEmail := _cEmailDir//SubStr(cEmail,1,Len(cEmail)-1)
		
		DBSelectArea("TRBZZL")
		TRBZZL->(DBCloseArea())
		
	EndIf
			
	//====================================
	// Chama a função para envio do e-mail
	//====================================
	U_ITENVMAIL( "", cEmail, "", cEmail, cGetAssun, _cHtml, "", _aConfig[01], _aConfig[02], _aConfig[03], _aConfig[04], _aConfig[05], _aConfig[06], _aConfig[07], @_cEmlLog )
EndIf
        
//=====================================
//Volto parâmetro para seu valor padrão
//=====================================
PutMV("MV_WFHTML",.T.)

If !Empty( _cEmlLog ) .And. !_lCriaAmb
	U_ITMsg( _cEmlLog + " " + cEmail, 'Término do processamento!' , ,2 )
Else
	FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00106"/*cMsgId*/, "MCOM00106 - Término do processamento de e-mail de Pedidos Liberados: - " + _cEmlLog/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
EndIf

If _lCriaAmb

	//=============================================================
	// Limpa o ambiente, liberando a licença e fechando as conexoes
	//=============================================================
	RpcClearEnv()

	FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM00107"/*cMsgId*/, "MCOM00107 - Termino do envio da lista de liberação dos pedidos de compras da data: " + DToC(MV_PAR01) + " ate "+DToC(MV_PAR02) + " para os e-mails " + cEmail/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)

EndIf

Return

/*
===============================================================================================================================
Programa----------: MCOM01Grupo
Autor-------------: ALEX WALLAUER
Data da Criacao---: 30/01/2019
Descrição---------: Função RETORNA OS APROVADORES do grupo de aprovadores
Parametros--------: Grupos
Retorno-----------: _aProv
===============================================================================================================================
*/
Static Function MCOM01Grupo(cGetGrpA)

Local aGrupos:=StrTokArr(AllTrim(cGetGrpA), ";" ) , A
Local _aProv:={}
Local _bUserN := {|x| UsrFullName(x)}

SAL->(DBSetOrder(1))
For A := 1 To Len(aGrupos)
	If SAL->(DBSeek(xFilial("SAL")+aGrupos[A]))
		While !(SAL->(Eof())) .And. AllTrim(aGrupos[A]) == SAL->AL_COD
			aAdd(_aProv,{SAL->AL_NIVEL,AllTrim(Eval(_bUserN,SAL->AL_USER))})
			SAL->(DBSkip())
		EndDo
	EndIf
Next
Return _aProv
