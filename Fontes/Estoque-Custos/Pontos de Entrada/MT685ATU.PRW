/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa--------: MT685ATU
Autor-----------: Josué Danich Prestes
Data da Criacao-: 23/09/2015
Descrição-------: P.E. na rotina de apontamento de perdas chamado logo após gravar a SD3 - Chamado 11951
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
User Function MT685ATU()

Local _cDoc := ""

//Grava campo D3_I_ORIGE  com função que gerou
DBSelectArea("SD3")	                     	
SD3-> ( DBSetOrder(4) )

If SD3->(DBSeek( xFilial("SD3") + SBC->BC_SEQSD3 ) )
	_cDoc := AllTrim(SD3->D3_DOC)	
	SD3-> ( DBSetOrder(2) )
	SD3-> ( DBGoTop() )

	If SD3->(DBSeek( xFilial ("SD3") + _cDoc ))
		While AllTrim(SD3->D3_DOC) == _cDoc
			RecLock("SD3",.F.)    
			SD3->D3_I_ORIGE := funname()	
			("SD3")->(MSUnLock())
			SD3->(DBSkip ())
		EndDo
	EndIf
EndIf

Return
