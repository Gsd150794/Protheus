/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Alex Wallauer |29/12/2020| Chamado 35108. Ajuste para chamar a função u_UCFG001(1)
Alex Wallauer |02/02/2021| Chamado 34262. Remoção de bugs apontados pelo Totvs CodeAnalysis.
Lucas Borges  |02/10/2025| Chamado 51526. Modificada forma para recuperar a matrícula do usuário.
Jose Gavetti  |27/11/2025| Chamado 51341. __cUserId não deve ter seu conteúdo alterado orientação TOTVS. 
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
================================================================================================================================
Programa----------: MTA440C9
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 15/03/2010
Descrição---------: Ponto de Entrada apos a liberacao do pedido de venda, para gravar a fililal + matricula do usuario, a data e a hora da liberacao do pedido de venda. 
Parametros--------: Nenhum
Retorno-----------: Nenhum
================================================================================================================================
*/
User Function MTA440C9

Local _aArea    := FWGetArea()        As Array
Local _aAreaSC9 := SC9->(FWGetArea()) As Array
Local aUsuario  := {}                 As Array
Local cUserCod  := ""                 As Character

If Type("_cCodUsuario") = "C"
   If !Empty(_cCodUsuario)
      cUserCod := _cCodUsuario
   EndIf
EndIf

If Empty(cUserCod) .And. !Empty(__cUserId)
    cUserCod := __cUserId
Endif

aUsuario := FWSFAllUsers({cUserCod}, {"USR_FILIAL"})

While SC9->(!Eof()) .And. SC6->C6_FILIAL == SC9->C9_FILIAL .And. SC9->C9_PEDIDO = SC6->C6_NUM
   SC9->(RecLock("SC9",.F.))
   If Len(aUsuario) > 0
      SC9->C9_I_USLIB := FWSFAllUsers({cUserCod},{"USR_FILIAL"})[1][3]+FWSFAllUsers({cUserCod},{"USR_CODFUNC"})[1][3]
   Endif
   SC9->C9_I_DTLIB := Date()
   SC9->C9_I_HRLIB := Time() 
   SC9->(MSUnLock())  
   SC9->(DBSkip())
EndDo   
      
FWRestArea(_aAreaSC9)              
FWRestArea(_aArea)

Return
