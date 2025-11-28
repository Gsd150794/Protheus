/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Alexandre V.  |20/07/2015| Chamado 10978. Atualização das rotinas.
Alexandre V.  |28/08/2015| Chamados 11497/11578. Ajuste para não bloquear o estorno da classificação de documentos.
Lucas Borges  |22/04/2019| Chamado 28895. Criada exceção para não gerar Recepção de Leite de Terceiros.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: A140EXC
Autor-------------: Alexandre Villar
Data da Criacao---: 24/02/2014
Descrição---------: Validação da exclusão dos documentos de entrada
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function A140EXC

Local _lRet		:= .T.
Local _lProdLt	:= .F.
Local _lExtZLX	:= .F.
Local _cCFOP	:= SuperGetMV("LT_CFEXCL3",.F.,"1925/2925")

If SF1->F1_TIPO == "N"

	DBSelectArea("SD1")
	SD1->( DBSetOrder(1) )
	If SD1->( DBSeek( xFilial("SD1") + SF1->( F1_DOC + F1_SERIE + F1_FORNECE + F1_LOJA ) ) )
		
		If Empty( SD1->D1_NFORI ) .And. Empty( SD1->D1_SERIORI )
		
			While SD1->( !Eof() ) .And. SD1->(D1_FILIAL+D1_DOC+D1_SERIE+D1_FORNECE+D1_LOJA) == xFilial("SD1")+SF1->(F1_DOC+F1_SERIE+F1_FORNECE+F1_LOJA) .And. !AllTrim(SD1->D1_CF) $ _cCFOP
				
				DBSelectArea('ZA7')
				ZA7->( DBSetOrder(2) )
				If ZA7->( DBSeek( xFilial('ZA7') + AllTrim(SD1->D1_COD) ) )
					DBSelectArea("ZLX")
					ZLX->( DBSetOrder(2) )
					If ZLX->( DBSeek( xFilial("ZLX") + SF1->( F1_DOC + F1_SERIE + F1_FORNECE + F1_LOJA ) ) )
						If ZLX->ZLX_STATUS == '1' .And. Empty( ZLX->ZLX_CODANA )
							ZLX->( RecLock( "ZLX" , .F. ) )
							ZLX->( DBDelete() )
							ZLX->( MSUnLock() )
						Else
							MsgStop("Não é permitido excluir Documentos que estão vinculados à uma Recepção de Leite de Terceiros no módulo Gestão do Leite!","A140EXC01")
						    _lRet := .F.
						EndIf
						_lExtZLX := .T.
					EndIf
					_lProdLt := .T.
				EndIf
			
				SD1->( DBSkip() )
			EndDo
		
		EndIf
	
	EndIf
	
	If _lRet .And. _lProdLt .And. !_lExtZLX
		MsgStop("O Documento atual contém produto(s) referente(s) à Recepção de Leite porém não foram encontrados dados da Recepção no módulo Gestão do Leite! "+;
					"É recomendável verificar se ficaram registros em aberto na Gestão do Leite para o documento atual que foi excluído.","A140EXC02")
	EndIf
	
EndIf

Return( _lRet )
