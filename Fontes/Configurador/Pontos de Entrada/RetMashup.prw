/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
André Lisboa  |27/10/2016| Tratativa para os campos DDD para quando o retorno For vazio - Chamado 17410
Darcio		  |20/01/2017| Foi incluído o tratamento para gravar a data de execução do mashup, mais os campos de retorno do
			  |			 | mashup. Chamado 17503
Lucas Borges  |17/10/2019| Removidos os Warning na compilação da release 12.1.25. Chamado 28346
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: RetMashup
Autor-------------: Andre Lisboa
Data da Criacao---: 18/10/2016
Descrição---------: Ponto de Entrada para tratar retorno dos Mashups
Parametros--------: ParamIXB
Retorno-----------: xRet
===============================================================================================================================
*/
User Function RetMashup()       

Local cAlias 	:= ParamIXB[1] 		// Alias da tabela
Local cMashup 	:= ParamIXB[2] 		// Nome do serviço do Mashup
Local cCampo 	:= ParamIXB[4] 		// Campo de retorno
Local xConteudo := ParamIXB[5]      // Conteúdo 
Local xRet

If cMashup == "ReceitaFederal.CNPJ"
	If AllTrim(cAlias) == "SA1"
		If AllTrim(cCampo) == "A1_TEL"
 			xRet	  := SubStr(xConteudo,5,10) //Telefone
			If !Empty(xConteudo)
				M->A1_DDD := SubStr(xConteudo,2,2)  //DDD
			EndIf	
		EndIf
		If AllTrim(cCampo) == "A1_I_SITRF"
			xRet	  := xConteudo //Situcao na RF
		EndIf
		If AllTrim(cCampo) == "A1_I_DTSRF"
			xRet	  := xConteudo //Data da consulta Situcao na RF
		EndIf			
	Else
		If AllTrim(cCampo) == "A2_TEL"
 			xRet	  := SubStr(xConteudo,5,10) //Telefone
			If !Empty(xConteudo)
				M->A2_DDD := SubStr(xConteudo,2,2)  //DDD
			EndIf	
		EndIf
		If AllTrim(cCampo) == "A2_I_SITRF"
			xRet	  := xConteudo //Situcao na RF
		EndIf
		If AllTrim(cCampo) == "A2_I_DTSRF"
			xRet	  := xConteudo //Data da consulta Situcao na RF
		EndIf
	EndIf				    
EndIf	
	
If cMashup == "Sintegra.ConsultaNacional"
	If AllTrim(cAlias) == "SA1"
		If AllTrim(cCampo) == "A1_INSCR"       //Inscrição Estadual
			xRet := StrTran(xConteudo,".","")
		EndIf	
	Else
		If AllTrim(cCampo) == "A2_INSCR"       //Inscrição Estadual
			xRet := StrTran(xConteudo,".","")
		EndIf	
	EndIf
EndIf		

If Empty(AllTrim(xConteudo))
	&("M->" + AllTrim(cCampo)) := Space(TamSX3(AllTrim(cCampo))[1])
Else
	&("M->" + AllTrim(cCampo)) := xConteudo
EndIf

If cMashup == "ReceitaFederal.CNPJ"
	If Alias() == "SA1"
		M->A1_I_DTEXE	:= Date()
	ElseIf Alias() == "SA2"
		M->A2_I_DTEXE	:= Date()
	EndIf              
EndIf

Return xRet
