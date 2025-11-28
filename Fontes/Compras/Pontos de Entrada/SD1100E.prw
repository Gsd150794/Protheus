/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Alexandre V.  |28/08/2015| Chamados 11497/11578. Ajuste para não bloquear o estorno da classificação de documentos.
Lucas Borges  |06/06/2017| Chamado 14511. Ajustada validação para não executar o PE no fechamento do Leite
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa--------: SF1100E
Autor-----------: Alexandre Villar
Data da Criacao-: 26/11/2014
Descrição-------: Ponto de entrada após a exclusão da nota fiscal
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/

User Function SD1100E

Local _aArea	:= FWGetArea()
Local _cStatus	:= ''
Local _lRLeite	:= !AllTrim( Upper( FUNNAME() ) ) $"U_MGLT009/MGLT010"

If _lRLeite
	DBSelectArea('ZLX')
	ZLX->( DBSetOrder(2) )
	If ZLX->( DBSeek( xFilial('ZLX') + SF1->( F1_DOC + F1_SERIE + F1_FORNECE + F1_LOJA ) ) )
	
		If FunName() == "MATA103" .Or. ( FunName() == "MATA140" .And. SF1->F1_STATUS <> 'A' )
			
			If ZLX->ZLX_STATUS == '1' .And. Empty( ZLX->ZLX_CODANA )
				
				ZLX->( RecLock( 'ZLX' , .F. ) )
				ZLX->( DBDelete() )
				ZLX->( MSUnLock() )
				
			Else
				
				If ZLX->ZLX_STATUS <> '1'
					_cStatus := IIf( !Empty( ZLX->ZLX_CODANA ) , IIf( ZLX->ZLX_STATUS == '2' , 'CLASSIFICADO' , 'FECHADO' ) , 'PENDENTE' )
				Else
					_cStatus := 'vinculado à uma análise de qualidade'
				EndIf
				
				MessageBox(	'Existe registro de Recepção de Leite de Terceiros relacionado ao Documento de Entrada excluído! ' +;
							'A rotina não pode excluir esse registro pois o mesmo encontra-se '+ _cStatus +'.' , 'Atenção!' , 16 )
				
			EndIf
		
		Else
		
			ZLX->( RecLock( 'ZLX' , .F. ) )
			ZLX->ZLX_VLRNF	:= 0
			ZLX->ZLX_ICMSNF	:= 0
			ZLX->( MSUnLock() )
			
		EndIf
	
	EndIf
EndIf
FWRestArea( _aArea )

Return
