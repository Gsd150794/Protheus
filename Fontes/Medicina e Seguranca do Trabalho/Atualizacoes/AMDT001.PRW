/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |02/10/2019| Chamado 28346. Removidos os Warning na compilação da release 12.1.25.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: AMDT001
Autor-------------: Josué Danich Prestes
Data da Criacao---: 01/09/2015
Descrição---------: Retorna saldo do produto no armazém de EPI
Parametros--------: _cproduto - código do produto consultado
Retorno-----------: _cRet - quantidade do produto formatada para consulta padrão
===============================================================================================================================
*/
User Function AMDT001(_cproduto)

Local _aArea 	:= FWGetArea()
Local _cRet		:= PadL(Transform(0,"@E 9,999,999.99"),15)
Local _cArmaz 	:= U_ITGETMV( "IT_ESTEPI" , "00" )

DBSelectArea("SB2")
If SB2->(DBSeek(xFilial("SB2") + _cproduto + _cArmaz))
	_cRet := PadL(Transform(SaldoSb2(),"@E 9,999,999.99"),15)
EndIf

FWRestArea(_aArea)

Return _cRet
