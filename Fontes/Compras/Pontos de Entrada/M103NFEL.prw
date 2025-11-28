/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |16/05/2022| Chamado 40106. Preencher com zeros à esquerda assim como no número do documento.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: M103NFEL
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 19/08/2021
Descrição---------: Ponto de Entrada utilizado para inserir informações nas abas "Nota Fiscal Eletrônica", "Informações DANFE"
					e "Informações Adicionais" no momento da inclusão e da classificação da nota, para que as informações fiquem
					visíveis no momento da digitação da nota. Chamado 37521
Parametros--------: ParamIXB[1][1] -> C -> Identificação do campo que está sendo validado.
					ParamIXB[1][2] -> C -> Código da UF digitada no campo F1_EST
					ParamIXB[1][3] -> A -> Array com o conteúdo dos campos da aba Nota Fiscal Eletrônica
					ParamIXB[3][1] -> C -> F1_NFELETR
					ParamIXB[3][2] -> C -> F1_CODNFE
					ParamIXB[3][3] -> D -> F1_EMINFE
					ParamIXB[3][4] -> C -> F1_HORNFE
					ParamIXB[3][5] -> N -> F1_CREDNFE
					ParamIXB[3][6] -> C -> F1_NUMRPS
					ParamIXB[3][7] -> C -> F1_MENNOTA
					ParamIXB[3][8] -> C -> F1_MENPAD
					ParamIXB[1][4] -> A -> Array com o conteúdo dos campos da aba Informações DANFE
					ParamIXB[1][5] -> A -> Array com o conteúdo dos campos da aba Informações Adicionais
Retorno-----------: Array multidimensional, contendo os arrays recebidos como parâmetro 3, 4 e 5 contendo as informações 
					inseridas pelo ponto de entrada.
===============================================================================================================================
*/
User Function M103NFEL

Local _aNfEletr := ParamIXB[3]
Local _aDanfe 	:= ParamIXB[4]
Local _aInfAdic := ParamIXB[5]

If AllTrim(cEspecie) == "NFDS"
	_aNfEletr[1] := StrZero( Val( cNFiscal ) , TamSX3('F1_DOC')[01] )
	_aNfEletr[3] := dDEmissao
EndIf

Return {_aNfEletr,_aDanfe,_aInfAdic}
