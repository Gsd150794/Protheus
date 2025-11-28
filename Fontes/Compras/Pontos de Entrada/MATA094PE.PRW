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
Programa----------: MATA094
Autor-------------: Alex Wallauer
Data da Criacao---: 15/01/2019
Descrição---------: PE do MVC da Aprovação de Documentos Function MATA094() 
Parametros--------: Nenhum
Retorno-----------: .T. ou .F. 
===============================================================================================================================
*/ 
User Function MATA094

Local _aParam:= ParamIXB

If _aParam <> NIL
	
	_oObj		:= _aParam[01]
	_cIdPonto	:= _aParam[02]
	nOper		:= _oObj:GetOperation()
	
	If _cIdPonto = "FORMPOS" .And. nOper = 4
		
		SAL->(DBSetOrder(3))
		SAL->(MsSeek( xFilial("SAL")+SCR->CR_GRUPO+SCR->CR_APROV ))
		
		DHL->(DBSetOrder(1))
		DHL->(MsSeek(xFilial("DHL")+SAL->AL_PERFIL))//Perfil
		_nLimPerfil:=DHL->DHL_LIMMAX
		
		_cAlias:=GetNextAlias()
		BeginSql Alias _cAlias
			SELECT SUM(SC7.C7_TOTAL) C7TOTAL
			FROM %Table:SC7% SC7
			WHERE SC7.C7_FILIAL=%xFilial:SC7% AND	SC7.C7_NUM = %Exp:SCR->CR_NUM% AND ;
			SC7.%NotDel%
		EndSql
		_nTotal:=(_cAlias)->C7TOTAL
		(_cAlias)->(DBCloseArea())
		_lRet:=.T.
		If _nTotal > _nLimPerfil //.AND. _nTotal > _nLimGrupo
			
			U_ITMsg("Valor da Aprovação maior que o Limte do Perfil do Aprovador",'Atenção!',;
		            "Aprove ate o Limite do Perfil: "+Str(DHL->DHL_LIMMAX,18,2),1,,,.T.)//+CHR(13)+CHR(10)+"Limite do Grupo: "+Str(SAK->AK_LIMMAX,18,2)  ,2,,,.T.)
			
		    _lRet:=.F.
			
		EndIf
		
		Return _lRet
		
	EndIf
	
EndIf

Return .T.
