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
Programa----------: QDOLPDFIMP()
Autor-------------: Julio de Paula Paz
Data da Criacao---: 10/06/2024
Descrição---------: Ponto de entrada que permite habilitar e desabilitar recursos de impressão de documentos.
Parametros--------: Nenhum
Retorno-----------: _lRet = .T. = Habilita a impressão de Documentos.
                            .F. = Desabilita a impressão de Documentos.
===============================================================================================================================
*/  
User Function QDOLPDFIMP

Local _lRet := .F. 

QAA->(DBSetOrder(1)) // QAA_FILIAL+QAA_MAT

If QAA->(MsSeek(xFilial("QAA") + cmatcod ))
   If QAA->QAA_DISTSN == "1" // 1=SIM
      _lRet := .T.  
   EndIf 
EndIf 

Return _lRet 

