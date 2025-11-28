/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Josué Danich  |05/09/2018| Chamado 25283. Retirada de gravação e posicionamento SCP
Alex Wallauer |25/06/2020| Chamado 33355. Gravação do campo CP_I_SITWF do SCP.
Lucas Borges  |02/10/2025| Chamado 51526. Modificada forma para recuperar a matrícula do usuário.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: MT105GRV
Autor-------------: Frederico O. C. Jr
Data da Criacao---: 28/10/2008
Descrição---------: Este Ponto de Entrada e chamado apos conseguir gravar (l105GRV=.T.) os dados no arquivo SCP.
Parametros--------: ParamIXB => nOpcao (Numerico)
                    [1] Inclusado
                    [2] Alteracao
                    [3] Exclusao
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MT105GRV()
Local _aArea := FWGetArea()
Local _cNum	 := SCP->CP_NUM
Local _nscp  := SCP->(RECNO()) 
Local nOpcao := ParamIXB

If nOpcao = 3 //Exclusao 
   Return .T.
EndIf		
		
SCP->(DBSetOrder(1))
SCP->(DBSeek(xFilial("SCP")+_cNum))

While (!SCP->(Eof()) .And. ( xFilial("SCP")+_cNum == SCP->CP_FILIAL+SCP->CP_NUM )) .And. !ISINCALLSTACK("MDTA695")

	SCP->(RecLock("SCP",.F.))
	SCP->CP_I_DTSOL := Date()
	SCP->CP_I_RSSOL := Time()
	SCP->CP_I_CDUSU := FWSFAllUsers({__cUserID},{"USR_FILIAL"})[1][3]+FWSFAllUsers({__cUserID},{"USR_CODFUNC"})[1][3]
	SCP->CP_I_GRAPR := Posicione("ZZL",4,xFilial("ZZL")+Trim(SCP->CP_SOLICIT),"ZZL_GRPAPR")
	SCP->CP_I_SITWF	:= "1"
	SCP->(MSUnLock())
		
	SCP->(DBSkip())
	
EndDo
		
FWRestArea(_aArea)
SCP->(DBGoTo(_nscp))
	
Return .T.
