/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Alex Wallauer |19/01/2024| Chamado 46095. Ajuste na validação do centro de custo ser válido com campo de investimento.
Julio Paz     |21/10/2024| Chamado 48697. Validar a data de emissão da Solicitação ao Armazém, para não ser superior a data do 
			  |			 | dia da inclusão ou Alteração do cadastro.
Lucas Borges  |19/09/2025| Chamado 50617. Migração dos parâmetros da ZP1 para SX6
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: MTA105OK
Autor-------------: Xavier
Data da Criacao---: 13-04-2015
Descrição---------: Ponto de entrada na validação do OK da solicitação ao armazem.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MTA105OK

Local _aArea 	:= FWGetArea()
Local _lRet 	:= .T.
Local _cUsr	:= ""
Local _cSol 	:=  ""
Local _nni 	:= 0
Local _cmens	:= ""
Local _cCC		:= ""
Local _cINVES := ""
Local _cLOCIN := ""
Local _lexcep := .F. , N
Local _cloca  := SuperGetMV("IT_MOTINV",.F.,"15")

If ALTERA
	_cUsr := Posicione("ZZL",4,xFilial("ZZL")+UsrRetName(__cUserId),"ZZL_GRPAPR")
	_cSol := Posicione("ZZL",4,xFilial("ZZL")+SCP->CP_SOLICIT,"ZZL_GRPAPR")
	
	If (_cUsr # _cSol) .And. _lRet .And. _cUsr <> "0"
		_lRet := .F.
		_cmens += "Operação invalida ! Usuário não pertence ao departamento do solicitante."
	EndIf
EndIf

_nni    := n
lDIf    :=.F.
cCentroC:=""

For n := 1 To Len(acols)

	_lexcep := .F.

	If !(acols[n][Len(aheader)+1])
	
		//lê campos
		_cCC 	:= acols[n][aScan(aHeader , {|X| Upper( AllTrim( X[2] ) ) == "CP_CC"     } )]
		_cINVES	:= acols[n][aScan(aHeader , {|X| Upper( AllTrim( X[2] ) ) == "CP_I_INVES"     } )]
		_cLOCIN	:= acols[n][aScan(aHeader , {|X| Upper( AllTrim( X[2] ) ) == "CP_I_LOCIN"     } )]
		_cMOTIN	:= acols[n][aScan(aHeader , {|X| Upper( AllTrim( X[2] ) ) == "CP_I_MOTIV"     } )]

        If Empty(cCentroC)
           cCentroC+=" [ "+_cCC+" ]"
        EndIf

        If !_cCC $ cCentroC
           cCentroC+=" [ "+_cCC+" ]"
           lDif:=.T.
        EndIf

		//verifica se é exceção de validação
		If 	AllTrim(_cMOTIN) $ AllTrim(_cloca) 
		  _lexcep := .T.
		EndIf
		
		//Verifica se campo de centro de custo é válido com campo de investimento
		If SubStr(AllTrim(_cCC),1,5) $ AllTrim(u_vldcc()) .And. _cINVES <> "S" .And. !(Empty( _cCC )) .And. !(_lexcep) .And. !FWIsInCallStack( "MDTA695" )
			_cmens += "Item " + StrZero(n,4) + " - Para Centro de custo da filial é preciso que seja solicitação de investimento." + CRLF + CRLF
			_lRet := .F.
		EndIf

		//Verifica se campo de centro de custo é válido com campo de investimento
		If !(SubStr(AllTrim(_cCC),1,5) $ AllTrim(u_vldcc())) .And. _cINVES = "S"  .And. !(_lexcep)
			_cmens += "Item " + StrZero(n,4) + " - Para investimento é preciso campo de centro de custo válido." + CRLF + CRLF
			_lRet := .F.
		EndIf

		//Verifica se campo investimento não está como S se o campo Local de investimento estiver preenchido
		If  _cINVES <> "S" .And. !(Empty( _cLOCIN )) 
			_cmens += "Item " + StrZero(n,4) + " - Para ter Local de investimento é preciso ser solicitação de investimento." + CRLF + CRLF
			_lRet := .F.
		EndIf

		//Verifica se campo Local de investimento está preenchido se campo investimento está preenchido
		If  _cINVES = "S"  .And. (Empty( _cLOCIN )) 
			_cmens += "Item " + StrZero(n,4) + " - Para solicitação de investimento é obrigatório Local de investimento." + CRLF + CRLF
			_lRet := .F.
		EndIf

		//Se Local de investimento está preenchido garante que a descrição de investimento está preenchida
		If  _cINVES = "S"	.And. !(Empty( _cLOCIN )) 
 			acols[n][aScan(aHeader , {|X| Upper( AllTrim( X[2] ) ) == "CP_I_DESIN"     } )] := 	Posicione("ZZI",1,xFilial("ZZI")+_cLOCIN,"ZZI_DESINV")
 		EndIf
	EndIf
Next

n := _nni

//============================================
//Mostra lista de itens com problema
//============================================
If !(_lRet) .And. !(Empty(_cmens))
	MessageBox( 'Problemas nos itens abaixo: ' + CRLF + CRLF + _cmens + CRLF + CRLF+;
					'Caso necessário solicite a manutenção à um usuário com acesso ou, se necessário, solicite o acesso à área de TI/ERP.' , 'Atenção!' , 48 )
EndIf

If _lRet .And. lDIf 
   U_ITMsg("Centro de custos distintos: "+cCentroC,;
           "ATENCAO",;
           "Altere os centros de custo da SA mantendo um unico centro de custo para todos os itens.",1)
   _lRet := .F.
EndIf

//================================================================= 
// Valida a data de emissão da Solicitação ao Armazém para 
// não ser maior que a data do dia da inclusão/alteração.
//=================================================================
If _lRet .And. DA105DATA > Date()
    U_ITMsg("A data de emissão da Solicitação ao Armazém não pode ser superior a data de hoje. ",;
           "Atenção",;
           "Informe uma data de emissão igual ou inferior a data de hoje.",1)
   _lRet := .F.
EndIf 

FWRestArea(_aArea)

Return _lRet
