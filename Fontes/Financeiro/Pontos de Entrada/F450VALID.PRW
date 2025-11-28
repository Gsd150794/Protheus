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
Programa--------: lFA450BU
Autor-----------: Julio de Paula Paz
Data da Criacao-: 20/01/2020
Descrição-------: Ponto de entrada na validação final das digitações dos dados da tela de parâmetros iniciais da rotina:
                  Compensação de titulos entre carteiras. Chamado 31103.
Parametros------: Nenhum
Retorno---------: _lRet = .T. ou .F.
===============================================================================================================================
*/
User Function F450VALID()                                         
Local _lRet := .T.

Begin Sequence               
 
   If U_ITMsg("Desconsidera as Lojas de Cliente e Fornecedor que foram informadas?" , "Atenção" , ,2,2,2) 
      cLjCli := Space(4)
      cLjFor := Space(4)
   EndIf
   
End Sequence

Return _lRet 
 