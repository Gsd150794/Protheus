/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Alexandre V.  |   02/2015| Atualização dos P.E. que interferem na rotina de Fechamento do Leite
Alexandre V.  |28/08/2015| Chamados 11497/11578. Ajuste para não bloquear o estorno da classificação de documentos
Lucas Borges  |03/10/2019| Removidos os Warning na compilação da release 12.1.25. Chamado 28346
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: A100DEL
Autor-------------: Wesley M Martins
Data da Criacao---: 09/01/2009
Descrição---------: Ponto de entrada chamado antes da exclusão da nota fiscal
					Em que ponto: Chamado antes de qualquer atualização na exclusão e deve ser utilizado para validar se a 
					exclusão deve ser efetuada ou não.
Parametros--------: Nenhum
Retorno-----------: _lRet -> L -> .T. - prossegue com exclusao /.F. - abandona exclusão
===============================================================================================================================
*/
User Function A100DEL

Local _aArea		:= FWGetArea()
Local _cAlias		:= ""
Local _lRet			:= .T.

If FunName() == "MATA103" .Or. ( FunName() == "MATA140" .And. SF1->F1_STATUS <> 'A' )

	DBSelectArea('ZLX')
	ZLX->( DBSetOrder(2) )
	If ZLX->( DBSeek( xFilial('ZLX') + SF1->( F1_DOC + F1_SERIE + F1_FORNECE + F1_LOJA ) ) )
		If ZLX->ZLX_STATUS <> '1' .Or. !Empty( ZLX->ZLX_CODANA )
			MsgStop("Não é permitido excluir Documentos que estão vinculados à uma Recepção de Leite de Terceiros no módulo Gestão do Leite!","A100DEL001")
		    _lRet := .F.
		EndIf
	EndIf
	
	//====================================================================================================
	// Para a exclusao das notas fiscais do tipo devolucao sera averiguado se ja existe comissao com o 
	// status fechada, pois diante disso nao sera possivel realizar a exclusao.
	//====================================================================================================
	If _lRet .And. SF1->F1_TIPO == 'D'
	
		_cAlias := GetNextAlias()
		
		//====================================================================================================
		// Define os filtros para verificar se existe comissao fechada para a nota de devolucao a ser excluida
		//====================================================================================================
		BeginSql alias _cAlias
			SELECT COUNT(1) CONTREG
			  FROM %Table:SE3% SE3
			 WHERE SE3.D_E_L_E_T_ = ' '
			   AND SE3.E3_TIPO = 'NCC'
			   AND SE3.E3_I_FECH = 'S'
			   AND SE3.E3_FILIAL = %xFilial:SF1%
			   AND SE3.E3_NUM = %exp:SF1->F1_DOC%
			   AND SE3.E3_SERIE = %exp:SF1->F1_SERIE%
			   AND SE3.E3_CODCLI = %exp:SF1->F1_FORNECE%
			   AND SE3.E3_LOJA = %exp:SF1->F1_LOJA%
		EndSql

		If (_cAlias)->CONTREG > 0
			_lRet := .F.
			MsgStop("Não será possível realizar a exclusão da nota fiscal: " + SF1->F1_DOC + '/' + SF1->F1_SERIE + " , pois a mesma encontra-se com a comissão referente a esta nota com o status fechado.","A100DEL002")
		EndIf
		
		(_cAlias)->( DBCloseArea() )
	
	EndIf

EndIf

FWRestArea( _aArea )

Return( _lRet )
