/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Alex Wallauer |28/03/2025| Chamado 49970. Ajuste para não enviar se já tiver aprovado.
===============================================================================================================================
*/  

#Include "TOTVS.ch"

/*
======================================================== =======================================================================
Programa----------: MT010GRV
Autor-------------: Alex Wallauer Ferreira
Data da Criacao---: 28/06/2024
Descrição---------: PE no final da gravação do Cadastro de tabela de preço dentro da 
                    função Com010Grv()/COMA010.PRX. Chamado: 47732
Parametros--------: ParamIXB[1]: [1] Inclusao / [2] Alteracao / [3] Excluir / [4] Copiar
Retorno-----------: .T.
===============================================================================================================================
*/
User Function MT010GRV()

Local nOpcao :=ParamIXB[1] // [1] Inclusao / [2] Alteracao / [3] Excluir / [4] Copiar

If (nOpcao = 1 .Or. nOpcao = 2 .Or. nOpcao = 4) .And. M->AIA_I_DATE >= Date() .And. M->AIA_I_SITW <> "A"
   U_MCOM026("ENVIA")
EndIf

If (nOpcao = 1 .Or. nOpcao = 4)  
   U_ITMsg("TABELA GRAVADA COM SUCESSO, COM O CÓDIGO: "+M->AIA_CODTAB,'GRAVAÇÃO',,2)
EndIf

Return .T.
