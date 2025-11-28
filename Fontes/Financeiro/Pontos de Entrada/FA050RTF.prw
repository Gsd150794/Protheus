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
Programa----------: FA050RTF
Autor-------------: Guilherme D. Gesualdo
Data da Criacao---: 17/10/2012
Descrição---------: Ponto de Entrada para geração da retenção de PCC na emissão do Contas a Pagar
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function FA050RTF() 
 
aFilial := {}
nRegSM0 := SM0->(RECNO())
cEmpAtu := SM0->M0_CODIGO
cCnpj	:= SubStr(SM0->M0_CGC,1,8)
aArea   := FWGetArea()

DBSelectArea ("SM0")
DBGoTop()

While !Eof() .And. SM0->M0_CODIGO == cEmpAtu   

	If SubStr(SM0->M0_CGC,1,8) == cCnpj      
	
		aAdd(aFilial,AllTrim(SM0->M0_CODFIL))
		   
	EndIf   
	
DBSkip()
EndDo			

SM0->(DBGoTo(nRegSM0))

Return (aFilial)
