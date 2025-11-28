/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Alex Wallauer |10/12/2022| Chamado 42171. NOVO BOTÃO DE IMPORTAÇÃO DE SB2
Lucas Borges  |21/03/2025| Chamado 50221. Removida funcões desnecessárias
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: AEST049
Autor-------------: Alex Wallauer
Data da Criacao---: 11/08/2022   
Descrição---------: Cadastro Produto X CC X Conversão, CHAMADO 40988 
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/  
User Function AEST049()

Local cVldAlt := "U_AEST49Val()" // Validacao para permitir a alteracao. Pode-se utilizar ExecBlock.
Local cVldExc := ".T." // Validacao para permitir a exclusao. Pode-se utilizar ExecBlock.
Local aBotoes := {}

DBSelectArea("PBZ")
DBSetOrder(1)

AxCadastro("PBZ","Cadastro de Produto x Centro Custo X Conversão",cVldExc     ,cVldAlt  ,aBotoes)

Return

/*
===============================================================================================================================
Programa----------: AEST49Val
Autor-------------: Alex Wallauer
Data da Criacao---: 11/08/2022   
Descrição---------: VALIDACO DO CADASTRO PRODUTO X CC X CONVERSAO, CHAMADO 40988
Parametros--------: Nenhum
Retorno-----------: .T. ou .F.
===============================================================================================================================
*/  
User Function AEST49Val()

If Inclui 
   If PBZ->(DBSeek(xFilial("PBZ")+M->PBZ_CODIGO+M->PBZ_CUSTO))
      FWAlertWarning("Chave Produto + CC já cadastrada","AEST04901")
   	  Return .F.
   EndIf
EndIf

Return .T.
